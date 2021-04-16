# -*- encoding: utf-8 -*-
# stub: mongoid_paranoia 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "mongoid_paranoia".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Durran Jordan".freeze, "Josef \u0160im\u00E1nek".freeze]
  s.date = "2019-05-29"
  s.description = "There may be times when you don't want documents to actually get deleted from the database, but \"flagged\" as deleted. Mongoid provides a Paranoia module to give you just that.".freeze
  s.email = ["durran@gmail.com".freeze, "retro@ballgag.cz".freeze]
  s.homepage = "https://github.com/simi/mongoid-paranoia".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.14".freeze
  s.summary = "Paranoid documents".freeze

  s.installed_by_version = "2.6.14" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongoid>.freeze, ["~> 7.0"])
    else
      s.add_dependency(%q<mongoid>.freeze, ["~> 7.0"])
    end
  else
    s.add_dependency(%q<mongoid>.freeze, ["~> 7.0"])
  end
end
