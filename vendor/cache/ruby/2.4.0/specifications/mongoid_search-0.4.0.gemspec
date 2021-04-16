# -*- encoding: utf-8 -*-
# stub: mongoid_search 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "mongoid_search".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mauricio Zaffari".freeze]
  s.date = "2020-07-07"
  s.description = "Simple full text search implementation.".freeze
  s.email = ["mauricio@papodenerd.net".freeze]
  s.homepage = "https://github.com/mongoid/mongoid_search".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.14".freeze
  s.summary = "Search implementation for Mongoid ORM".freeze

  s.installed_by_version = "2.6.14" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fast-stemmer>.freeze, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<mongoid>.freeze, [">= 5.0.0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0.8.0"])
      s.add_development_dependency(%q<mongoid-compatibility>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 11.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.4"])
    else
      s.add_dependency(%q<fast-stemmer>.freeze, ["~> 1.0.0"])
      s.add_dependency(%q<mongoid>.freeze, [">= 5.0.0"])
      s.add_dependency(%q<database_cleaner>.freeze, [">= 0.8.0"])
      s.add_dependency(%q<mongoid-compatibility>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 11.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.4"])
    end
  else
    s.add_dependency(%q<fast-stemmer>.freeze, ["~> 1.0.0"])
    s.add_dependency(%q<mongoid>.freeze, [">= 5.0.0"])
    s.add_dependency(%q<database_cleaner>.freeze, [">= 0.8.0"])
    s.add_dependency(%q<mongoid-compatibility>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 11.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.4"])
  end
end
