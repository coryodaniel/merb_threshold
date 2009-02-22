desc "Run specs"
Spec::Rake::SpecTask.new("spec") do |t|
  t.libs = ['lib']
  unless ENV['NO_RCOV']
    t.rcov = true
    t.rcov_opts << '--exclude' << "spec,gems"
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
    t.rcov_opts << '--only-uncovered'
  end
  
  t.spec_files = FileList['spec/spec_helper.rb','spec/**/*_spec.rb']

  t.spec_opts << "--color" << "--format" << "progress" #"specdoc"
end