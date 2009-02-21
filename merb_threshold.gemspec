# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_threshold}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Cory O'Daniel"]
  s.date = %q{2009-02-16}
  s.description = %q{Merb plugin that provides resource access rate limits and captcha'ing}
  s.email = %q{contact@coryodaniel.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/merb_threshold", "lib/merb_threshold/clients", "lib/merb_threshold/clients/recaptcha.rb", "lib/merb_threshold/controller", "lib/merb_threshold/controller/merb_controller.rb", "lib/merb_threshold/core_ext", "lib/merb_threshold/core_ext/fixnum.rb", "lib/merb_threshold/frequency.rb", "lib/merb_threshold/merbtasks.rb", "lib/merb_threshold/stores", "lib/merb_threshold/stores/session.rb", "lib/merb_threshold.rb", "spec/merb_threshold_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/coryodaniel}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Merb plugin that provides resource access rate limits and captcha'ing}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb>, [">= 1.0.7.1"])
    else
      s.add_dependency(%q<merb>, [">= 1.0.7.1"])
    end
  else
    s.add_dependency(%q<merb>, [">= 1.0.7.1"])
  end
end
