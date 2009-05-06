require 'rubygems'
require 'merb-helpers/time_dsl'

require 'merb-core'
require 'merb-core/test'

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'
  c[:session_secret_key]  = 'f1e532d42a798511504907cf28d9c660fe51ac91'
  c[:session_id_key] = '_merb_threshold_session_id'
  c[:reload_classes] = false
end

Merb::Plugins.config[:merb_threshold] = {
# TODO remove global catpcha keys
  :public_key           => nil,
  :private_key          => nil,
  :recaptcha            => true,
  :wait_partial         => 'shared/wait_partial',
  :captcha_partial      => 'shared/recaptcha_partial'
}
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold','frequency')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold','controller','merb_controller')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold','recaptcha_client')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold','helpers','recaptcha_helper')
require File.join(File.dirname(__FILE__), '..', 'lib', 'merb_threshold','helpers','wait_helper')

module Merb  
  class Controller
    include Merb::Threshold::Helpers
  end
end
Numeric.send :include, Merb::Threshold::Per

include Merb::Threshold

class Hash
  def to_json
    result = "{"
    result << self.map do |k, v|
      if ! v.is_a?(String)
        "\"#{k}\": #{v}"
      else
        "\"#{k}\": \"#{v}\""
      end
    end.join(", ")
    result << "}"
  end
end
  


RecaptchaClient.public_key  = '6LcnNgUAAAAAABrFyM-LuC53axOzHbE27afV4gxP'
RecaptchaClient.private_key = '6LcnNgUAAAAAAEqnr9HP9ofrChZTcuTjl_0FFnxF'