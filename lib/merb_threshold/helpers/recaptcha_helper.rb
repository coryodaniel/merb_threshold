module Merb
  module GlobalHelpers    
    ##
    # Display a captcha if the threshold has been exceeded
    #
    # @param threshold_name [~Symbol] key to look up
    #
    # @params opts [Hash] passed to partial as 'threshold_options'
    #   Pass any params intended for RecaptchaOptions
    #   Additionally may pass:
    #     :partial => "./path/to/alternate/partial"
    #     :ssl      => TRue|False
    #     :partial_opts => {} #options to pass to partial()
    #     Theses keys are deleted before being passed to RecapthaOptions
    #
    # @return [String]
    def captcha(threshold_name = nil, opts={})
      if threshold_name.is_a?(Hash)
        opts = threshold_name
        threshold_name = nil
      end
      
      # if its currently exceeded display captcha
      if currently_exceeded? threshold_key(threshold_name)
        _src_uri        = opts.delete(:ssl) ? RecaptchaClient::API_SSL_SERVER : RecaptchaClient::API_SERVER
          
        _encoded_key    = escape_html(RecaptchaClient.public_key)
        
        _recaptcha_partial = (opts.delete(:partial) || Merb::Plugins.config[:merb_threshold][:captcha_partial])
        _partial_opts   = opts.delete(:partial_opts) || {}
        
        _partial_opts.merge!({
          :src_uri            => _src_uri, 
          :encoded_key        => _encoded_key, 
          :threshold_options  => opts,
          :captcha_error      => escape_html(@captcha_error.to_s)
        })
        
        partial(_recaptcha_partial, _partial_opts)
      end
    end
  end
end