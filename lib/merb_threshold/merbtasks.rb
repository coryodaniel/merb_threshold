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
    Merb::Controller.send(:class_variable_get, "@@_threshold_map").each do |name,opts|
      limit = opts[:limit].is_a?(Array) ? 
        Merb::Threshold::Frequency.new(*opts[:limit]) : opts[:limit]
      puts " ~ #{name}: #{limit.to_s}"
    end
    # puts "\nThresholds:\n\n"
    # abstract_controller_classes.each do |klass|
    #   if klass.respond_to?(:subclasses_list)
    #     puts klass
    #     subklasses = klass.subclasses_list.sort.map { |x| Object.full_const_get(x) }
    #     unless subklasses.empty?
    #       subklasses.each { |subklass| 
    #         puts "- #{subklass}" 
    #         unless subklass._threshold_map.empty?
    #           subklass._threshold_map.each do |name,opts|
    #             limit = opts[:limit].is_a?(Array) ? 
    #               Merb::Threshold::Frequency.new(*opts[:limit]) : opts[:limit]
    #             puts "  ~ #{name}: #{limit.to_s}"  
    #           end
    #         else
    #           puts "  ~ no thresholds"
    #         end
    #       }
    #     else
    #       puts "~ no subclasses"
    #     end
    #     puts
    #   end
    # end
  end
end