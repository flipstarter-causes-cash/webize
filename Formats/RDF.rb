# coding: utf-8
class WebResource

  # file -> Repository
  def loadRDF graph: env[:repository] ||= RDF::Repository.new
    if node.file?                                                    # file
      graph << RDF::Statement.new(self, Type.R, 'http://www.w3.org/ns/posix/stat#File'.R)

      readRDF fileMIME, File.open(fsPath).read, graph
    elsif node.directory?                                            # directory
      (dirURI? ? self : join((basename || '') + '/').R(env)).dir_triples graph
    end
    self
  end

  # MIME, data -> Repository
  def readRDF format, content, graph
    return if content.empty?
    case format                                                    # content type:
    when /octet.stream/                                            #  blob
    when /^audio/                                                  #  audio
      audio_triples graph
    when /^image/                                                  #  image
      graph << RDF::Statement.new(self, Type.R, Image.R)
      graph << RDF::Statement.new(self, Title.R, basename)
    when /^video/                                                  #  video
      graph << RDF::Statement.new(self, Type.R, Video.R)
      graph << RDF::Statement.new(self, Title.R, basename)
    else
      if reader ||= RDF::Reader.for(content_type: format)          # find reader

        reader.new(content, base_uri: self){|_|graph << _}         # read RDF

        if format == 'text/html' && reader != RDF::RDFa::Reader    # read RDFa
          RDF::RDFa::Reader.new(content, base_uri: self){|g|
            g.each_statement{|statement|
              if predicate = Webize::MetaMap[statement.predicate.to_s]
                next if predicate == :drop
                statement.predicate = predicate.R
              end
              graph << statement }} rescue (logger.debug "⚠️ RDFa::Reader failure #{uri}")
        end
      else
        logger.warn ["⚠️ no RDF reader for " , format].join # reader not found
      end
    end    
  end

  # Repository -> 🐢 file(s)
  def saveRDF                                           # query pattern:
    timestamp = RDF::Query::Pattern.new :s, Date.R, :o  # timestamp
    creator = RDF::Query::Pattern.new :s, Creator.R, :o # sender
    to = RDF::Query::Pattern.new :s, To.R, :o           # receiver
    type = RDF::Query::Pattern.new :s, Type.R, :o       # type

    env[:repository] << RDF::Statement.new('#updates'.R, Type.R, 'http://www.w3.org/ns/ldp#Container'.R) # updates
    env[:repository].each_graph.map{|graph|             # graph
      g = graph.name ? (graph.name.R env) : graphURI    # graph URI
      f = [g.document, :🐢].join '.'                    # 🐢 location
      log = []

      unless File.exist? f
        RDF::Writer.for(:turtle).open(f){|f|f << graph} # save 🐢
        graph.subjects.map{|subject|                    # annotate resource(s) as updated
          env[:repository] << RDF::Statement.new('#updates'.R, 'http://www.w3.org/ns/ldp#contains'.R, subject)}

        log << ["\e[38;5;48m#{graph.size}⋮🐢\e[1m", [g.display_host, g.path, "\e[0m"].join] unless g.in_doc?
      end

      # if location isn't on timeline, link to timeline. TODO additional indexing. ref https://pdsinterop.org/solid-typeindex-parser/ https://github.com/solid/solid/blob/main/proposals/data-discovery.md#type-index-registry
      if !g.to_s.match?(HourDir) && (ts = graph.query(timestamp).first_value) && ts.match?(/^\d\d\d\d-/)

        t = ts.split /\D/                                            # split timestamp
        🕒 = [t[0..3], t.size < 4 ? '0' : nil, [t[4..-1],            # timeline containers
               ([g.slugs, [type, creator, to].map{|pattern|          # name tokens from graph and query pattern
                   slugify = pattern==type ? :display_name : :slugs  # slug verbosity
                   graph.query(pattern).objects.map{|o|              # query for slug-containing triples
                  o.respond_to?(:R) ? o.R.send(slugify) : o.to_s.split(/[\W_]/)}}]. # tokenize
                  flatten.compact.map(&:downcase).uniq - BasicSlugs)].          # apply slug skiplist
                compact.join('.')[0..125].sub(/\.$/,'')+'.🐢'].compact.join '/' # 🕒 path

        unless File.exist? 🕒
          FileUtils.mkdir_p File.dirname 🕒                          # create timeline container(s)
          FileUtils.ln f, 🕒 rescue FileUtils.cp f, 🕒               # hardlink 🐢 to 🕒, fallback to copy
          log.unshift [:🕒, ts] unless g.in_doc?
        end
      end
      logger.info log.join ' ' unless log.empty?}
    self
  end

  # Repository -> tree {s -> p -> o}
  def treeFromGraph
    tree = {}    # output tree
    inlined = [] # inlined-node list
    env[:repository].each_triple{|subj,pred,obj|
      s = subj.to_s                   # subject URI
      p = pred.to_s                   # predicate URI
      blank = obj.class == RDF::Node  # bnode?
      if blank || p == 'http://www.w3.org/ns/ldp#contains' # bnode or child-node?
        o = obj.to_s                  # object URI
        inlined.push o                # inline object
        obj = tree[o] ||= blank ? {} : {'uri' => o}
      end
      tree[s] ||= subj.class == RDF::Node ? {} : {'uri' => s} # subject
      tree[s][p] ||= []                                       # predicate
      tree[s][p].push obj}                                    # object
    inlined.map{|n|tree.delete n} # sweep inlined nodes from index
    env.has_key?(:updates) ? {'#updates' => tree['#updates']} : tree
  end
end

RDF::Format.file_extensions[:🐢] = RDF::Format.file_extensions[:ttl] # enable 🐢 suffix for turtle files

module Webize

  MetaMap = {}
  VocabPath = %w(metadata URI)

  # read metadata map from configuration files
  Dir.children([ConfigPath, VocabPath].join '/').map{|vocab|                # find vocab
    if vocabulary = vocab == 'rdf' ? {uri: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'} : RDF.vocab_map[vocab.to_sym] # enable our use of RDF symbol as vocab prefix
      Dir.children([ConfigPath, VocabPath, vocab].join '/').map{|predicate| # find predicate
        destURI = [vocabulary[:uri], predicate].join
        configList([VocabPath, vocab, predicate].join '/').map{|srcURI|     # find mapping
          MetaMap[srcURI] = destURI}}                                       # map predicate
    else
      Console.logger.warn "❓ undefined prefix #{vocab} referenced by vocab map"
    end}

  configList('blocklist/predicate').map{|p|MetaMap[p] = :drop}              # load predicate blocklist

end
