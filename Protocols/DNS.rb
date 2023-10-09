#!/usr/bin/env ruby
# coding: utf-8
# portions from MIT license Simple DNS server by Peter Cooper <https://gist.github.com/peterc/1425383>

require_relative '../index'

# if we used the system resolver we'd end up back at ourself, so use some upstream servers
require 'resolv'
require 'resolv-replace'
hosts_resolver = Resolv::Hosts.new('/etc/hosts')
dns_resolver = Resolv::DNS.new nameserver: %w(8.8.8.8 9.9.9.9 1.1.1.1)
Resolv::DefaultResolver.replace_resolvers([hosts_resolver, dns_resolver])

class DNSRequest
  attr_reader :server, :data, :domain

  def initialize(server, data)
    @server = server
    @data = data
    extract_domain
  end

  def extract_domain
    @domain = ''
    if @data[2].ord & 120 == 0
      idx = 12
      len = @data[idx].ord
      until len == 0 do
        @domain += @data[idx + 1, len] + '.'
        idx += len + 1
        len = @data[idx].ord
      end
    end
  end

  def response(val)
    return empty_response if domain.empty? || !val
    cname = val =~ /[a-z]/
    hA = "\x81\x00".force_encoding('ASCII-8BIT')
    hB = "\x00\x00\x00\x00".force_encoding('ASCII-8BIT')
    response = [data[0,2], hA, (data[4,2] * 2), hB].join
    response += data[12..-1]
    response += "\xc0\x0c".force_encoding('ASCII-8BIT')
    response += cname ? "\x00\x05".force_encoding('ASCII-8BIT') : "\x00\x01".force_encoding('ASCII-8BIT')
    response += "\x00\x01".force_encoding('ASCII-8BIT')
    response += [120].pack("N")
    if cname
      rdata = val.split('.').collect { |a| a.length.chr + a }.join + "\x00".force_encoding('ASCII-8BIT')
    else
      rdata = val.split('.').collect(&:to_i).pack("C*")
    end
    response += [rdata.length].pack("n")
    response += rdata
  end

  def empty_response
    response = "#{data[0,2]}\x81\x03#{data[4,2]}\x00\x00\x00\x00\x00\x00"
    response += data[12..-1]
  end
end
class DNSServer
  DefaultAddr = ENV['ADDR'] || '127.0.0.1'
  Cache = {}

  def run
    # if binding isn't allowed, change this port and run ../low_ports for iptables redirection, sudo setcap 'cap_net_bind_service=+ep' /usr/bin/ruby, sudo socat, etc
    Socket.udp_server_loop(53) do |data, src|
      r = DNSRequest.new(self, data)
      domain = r.domain
      hostname = domain.sub /\.$/,''
      if Cache.has_key? domain
        result = Cache[domain]
      else
        reverse = domain.index 'in-addr.arpa'
        domain = domain[0..reverse-2].split('.').reverse.join('.') if reverse
        resource = Webize::URI(['//', hostname].join)
        deny = resource.deny?
        result = Cache[domain] = deny ? DefaultAddr : Resolv.send((reverse ? :getname : :getaddress), domain) rescue (failed = true; DefaultAddr)
        color = if deny
                  "\e[38;5;#{resource.deny_domain? ? 196 : 202};7m"
                elsif failed
                  "\e[35;1m"
                elsif hostname.index('www.') == 0
                  nil
                else
                  "\e[38;5;51m"
                end
        puts [Time.now.iso8601[11..15],
              [color, "\e]8;;https://#{hostname}/\a#{hostname}\e]8;;\a\e[0m"].join].join ' '
      end
      src.reply r.response(result)
    end
  end
end

DNSServer.new.run