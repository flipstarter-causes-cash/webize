# WHAT

fix the web in post-production. some suggest we abandon it - we'd rather create the [web we want](https://webwewant.org/) via a healthy dose of format and protocol bridging to tools of the desired capability

# WHY

formative-era browsers display blank pages in the era of "single-page apps" while newer browsers execute remote code or too suffer the [blank-page](https://docs.google.com/presentation/d/120CBI6_gIGqKflXoGp8UMpge1OJ7hfHNNl7JLARUT_o/edit#slide=id.p) problem. default browser configuration - a privacy disaster instantly and silently reporting data to third parties as soon as a page is loaded - is increasingly the only state of affairs due to unavailability of plugins like [uBlock Origin](https://github.com/gorhill/uBlock) on popular mobile and embedded-webview browsers. browsers that aren't privacy messes riddled with surveillytics eager to display a blank page would be nice, but if business motives of the large browser vendors - coincidentally the biggest tracking companies themselves - haven't aligned to give users this basic functionality save for third-party plugins at risk of breakage on desktop browsers and unavailable on mobile, it may not be coming. [Palemoon](https://forum.palemoon.org/) has shown that lone-rangers can maintain a browser fork, but this requires individuals of exceptional motivation of which there are apparently only a few on the planet, and relying on their continued interest is hardly a safe bet.

on servers, most don't support [content negotiation](https://www.w3.org/DesignIssues/Conneg) or globally-identified graph data, only offering ad-hoc site-specific HTML/JSON/Protobuf subformats, making supplying your own interface, browser or cross-site data integrations difficult, tossing notions of low/no-code [serendipitous](https://noeldemartin.com/blog/interoperable-serendipity) mashups & data-reuse to the wayside while begging the developer to craft bespoke integrations involving site-specific APIs, account registrations and API keys, glued together by fiddling around writing code depending on site-specific API-client libraries. nothing says 'browse content' like 'do a bunch of tedious stuff including write custom code involving dependencies not in the distro package manager'. that's [considered normal](https://doriantaylor.com/the-symbol-management-problem#:~:text=age%20of%20APIs) these days - snowflake APIs demanding special treatment and the vast make-work project of [one-off](https://subconscious.substack.com/p/composability-with-other-tools) integrations.

# HOW

present a better server to the client via proxy. explicit/transparent/URI-rewrite modes are supported for wide compatibility including [non-HTTPS](http://michael.orlitzky.com/articles/lets_not_encrypt.xhtml) browsers and cert-pinned/guest-mode kiosks. a config for [Squid](http://www.squid-cache.org/) is included as a HTTPS frontend (pure-ruby SSL options coming as soon as i RTFM) while Ruby backend handlers are spun up as needed. servers are made [less bad](http://suckless.org/philosophy/), bestowed with content-negotiation, data mapped to a [universal](https://www.geoffreylitt.com/wildcard/salon2020/#expose-a-universal-data-structure) [model](https://www.w3.org/RDF/) available in a multitude of formats. clients need to know just [one API, HTTP](https://ruben.verborgh.org/blog/2013/11/29/the-lie-of-the-api/). blank pages are fixed by defining a site-specific CSS selector and/or regex to fish initial-state JSON out of the document or automatically in the case of compliant JSON-LD/Microdata/RDFa. we're obsessed with finding all the data on offer, so in addition to the formats afforded by Ruby's RDF library, there's a framework for site-specific data-mapping and mapping for non-RDF formats: Atom/RSS [feeds](https://karl-voit.at/2020/10/23/avoid-web-forums/), e-mails and miscellaneous stuff you might find on a filesystem. the proxy effectively adds a graph cache [to the hierarchy](https://gist.github.com/paniq/bf5b291949be14771344b19a38f042c0), facilitating offline scenarios and [automatic archiving](https://beepb00p.xyz/sad-infra.html)

whether mapping the modern app-web to HTML for [dillo](https://www.dillo.org/)/[elinks](http://elinks.or.cz/)/[eww](https://www.gnu.org/software/emacs/manual/html_mono/eww.html)/[links](http://links.twibright.com/)/[lynx](https://lynx.browser.org/)/[w3m](http://w3m.sourceforge.net/), Gemtext for [Geopard](https://ranfdev.com/projects/geopard/)/[Ladybird](https://awesomekling.github.io/Ladybird-a-new-cross-platform-browser-project/)/[Lagrange](https://gmi.skyjake.fi/lagrange/), or [Turtle](https://en.wikipedia.org/wiki/Turtle_(syntax)) for [Solid-compliant](https://gitter.im/solid/specification) [data browsers](https://github.com/solid/data-kitchen), your interface is [user-supplied](https://www.geoffreylitt.com/2021/03/05/bring-your-own-client.html) from a codebase [you control](https://www.gnu.org/philosophy/keep-control-of-your-computing.en.html#content). since user freedom and autonomy is paramount, one may opt to run 3rd-party JS in the original UI - in this case cyan entries in the log are often fresh trackingware startups you didn't know about yet. the imagination of the [surveillance economy](https://news.harvard.edu/gazette/story/2019/03/harvard-professor-says-surveillance-capitalism-is-undermining-democracy/) to think up new tricks is seemingly unbounded, and you may find this a useful toolkit to begin to respond, by never running Javascript again, and reducing or eliminating requests that make it out to the net and its proprietary cloud-services that buy and sell your data. when deprived of developer tools and plugins on a mobile OS, transparent-proxy mode is a way to have desktop-grade [visibility](https://github.com/OxfordHCC/tracker-control-android) into what's going on, and control it, via customized site-handlers or the domain deny list, while recording the data so it's not trapped in an app that won't run on the next version of Android or when VC funding pulls the plug.

we're intent on doing things with as minimal a set of dependencies, abstractions and lines of code as possible - this includes runtime dependencies like third party database engines. this library is in essence an experimental testbed for exploration on this trajectory. the main abstraction we've introduced is a Resource class, which itself subclasses from the RDF library. in the interest of immutability and eschewing runtime state, it's derived from a class that represents just the resource's identifier. we've paired it with an environment - transient request-time data containing the caller's preferences to guide codepath selections. input/output 'webizers' are defined as normal parsers/serializers in accordance with the RDF library convention. compatibility with these abstractions is a key part of enabling integration with the long-tail of filesystem, RDF and web libraries/tooling in Ruby, Java via JRuby (and possibly Clojure or Ruby-to-WASM compilation backends for browser deployment) and the shell.

after decades of use as a daily-driver for various aggregation/synchronization/news/chat/webmail workflows, most users have not needed to add things like runtime graph-database/triple-stores which have proven to be a complexity, configuration and system-resource overhead hurdle to adoption of other RDF-based solutions outside of well-budgeted situations like institutional repository SW with grant or university-funded sysadmin teams. ideally even if you're not a programmer you can figure out how to launch a webserver (without having to configure it first) and ctrl-C it when done, and not need to abstract your entire userspace (or multiple userspaces/VMs, orchestrated) with tools like Docker/Kubernetes/Terraform. welcome to the [user-centric](https://rbs.io/2019/05/a-revolution-in-your-pocket/), decentralized, human-scale edge web where git, [Tailscale](https://tailscale.com/blog/stuck-opening-the-socket/), the up-arrow and ctrl-C ought to be enough for most anyone. if you *want* to experiment with these things - say instant deployments of code updates to all your devices or advanced indexing capabilities with a SQLite backed graph DB - the codebase is designed to be evolvable and interoperable.

# WHERE

it's [your data](https://www.youtube.com/watch?v=-RoINZt-0DQ), and finding what you're looking for should be easy, even if your internet is down or you don't have [cloud](https://martin.kleppmann.com/2021/04/14/goodbye-gpl.html#the-enemy-has-changed) accounts, so on [localhost](http://localhost/) time-ordered data is made searchable by lightweight and venerable [find](https://www.gnu.org/software/findutils/manual/html_mono/find.html), [glob](https://en.wikipedia.org/wiki/Glob_(programming)) and [grep](https://www.gnu.org/software/grep/manual/grep.html). for more complicated queries, one can write [SPARQL](https://github.com/ruby-rdf/sparql) as the store comprises a [URI space](https://www.w3.org/DesignIssues/Axioms.html#uri) of RDF graph data. with Turtle files the [offline-first](https://offlinefirst.org/) / [local-first](https://www.inkandswitch.com/local-first.html) source of state, synchronization between devices can be handled by underlying file distribution tools such as [git](gemini://gemini.circumlunar.space/~solderpunk/gemlog/low-budget-p2p-content-distribution-with-git.gmi), [nncp](https://www.complete.org/nncp/), [scp](https://github.com/openssh/openssh-portable/blob/master/scp.c), [rsync](https://wiki.archlinux.org/index.php/Rsync) or [syncthing](https://syncthing.net/), at a higher-level by streaming RDF triples to other devices via [CRDTs](https://openengiadina.gitlab.io/dmc/) or [gossip networks](https://github.com/libp2p/specs/blob/master/pubsub/gossipsub/gossipsub-v1.1.md), or accessing remote nodes directly via HTTP services running on your personal [LAN](https://www.defined.net/nebula/)

# WHEN

in theory, this project can go away once clients and servers are [privacy respecting](https://privacypatterns.org/patterns/) and standards compliant in read/write APIs and formats. in reality, we've seen the reduction in user agency and nixing of generic access modes (protocols and formats, not platforms and products) in favor of vendor-controlled mobile and web apps, backed by "exciting" tech on (almost always remote) servers cultivating rented access to a small handful of proprietary hosting/API-platforms. basic GET requests are swapped for site-specific GRAPHQL queries - often via non-HTTP protocols like gRPC lacking mature and ubiquitous proxy tooling - and site-specific binary wire-formats with protobuf definitions as proprietary code unavailable for inspection or 3rd-party client code generation, while we don't know the queries since theyre referred to with the shortcut of an opaque hash. proprietary platforms continue to iterate on the inscrutable black-box dumb-terminal model they've loved selling since the 1960s.

# WHO

IX (or poka) on EFNet/Rizon(maybe one day OFTC/Libera) chat. msg me on IRC to notify if you've emailed the git address or created bug/issue/PR on an online git mirror as those accounts have solely been for public backups/clone-points so far

## further reading

[INSTALL](INSTALL.sh) script

[USAGE](USAGE.md) tips
