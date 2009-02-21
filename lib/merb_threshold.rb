if defined?(Merb::Plugins)  
  Merb::Plugins.config[:merb_threshold] = {
  # TODO remove global catpcha keys
    :public_key           => nil,
    :private_key          => nil,
    :recaptcha            => true,
    :wait_partial         => 'shared/wait_partial',
    :captcha_partial      => 'shared/recaptcha_partial'
  }
          
  module Merb
    module Threshold
    end
  end
  
  require 'merb-helpers/time_dsl'
  
  require "merb_threshold/frequency"
  require "merb_threshold/controller/merb_controller"
  require "merb_threshold/helpers/wait_helper"  
  
  include Merb::Threshold
  
  Merb::Plugins.add_rakefiles "merb_threshold/merbtasks"
  
  Merb::BootLoader.before_app_loads do
    if Merb::Plugins.config[:merb_threshold][:recaptcha]
      require 'merb_threshold/recaptcha_client'
      require 'merb_threshold/helpers/recaptcha_helper'
      RecaptchaClient.public_key  = Merb::Plugins.config[:merb_threshold][:public_key]
      RecaptchaClient.private_key = Merb::Plugins.config[:merb_threshold][:private_key]
    end
  end
end
