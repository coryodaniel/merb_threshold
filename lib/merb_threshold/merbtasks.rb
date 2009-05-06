require 'fileutils'
namespace :merb_threshold do    
  desc "Generate captcha partial OUT=./path/to/partials"
  task :generate_captcha do
    from  = File.dirname(__FILE__)
    to    = File.join(ENV['OUT'],'_recaptcha_partial.html.erb')
    FileUtils.cp File.join(from,'templates','_recaptcha_partial.html.erb'), to
    
    if File.exist? to
      puts "Captcha partial created: #{to}"
    else
      puts "Could not create partial: #{to}"
    end
  end

  desc "Generate wait partial OUT=./path/to/partials"
  task :generate_wait do
    from  = File.dirname(__FILE__)
    to    = File.join(ENV['OUT'],'_wait_partial.html.erb')
    FileUtils.cp File.join(from,'templates','_wait_partial.html.erb'), to
    
    if File.exist? to
      puts "Wait partial created: #{to}"
    else
      puts "Could not create partial: #{to}"
    end
  end
end

namespace :audit do
  desc "Print out all thresholds"
  task :thresholds => :merb_env do
    puts "Thresholds:"
    Merb::Controller.send(:class_variable_get, "@@_threshold_map").each do |name,opts|
      limit = opts[:limit].is_a?(Array) ? 
        Merb::Threshold::Frequency.new(*opts[:limit]) : opts[:limit]
      puts " ~ #{name}: #{limit.to_s}"
    end
  end
end