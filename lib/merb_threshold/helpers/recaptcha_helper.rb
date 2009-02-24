module Merb
  module Threshold
    module Helpers    
      ##
      # Display a captcha if the threshold has been exceeded
      #
      # @param threshold_name [~Symbol] key to look up
      #
      # @params opts [Hash] passed to partial as 'threshold_options'
      #   Pass any params intended for RecaptchaOptions
      #   Additionally may pass:
      #     :
      #     :partial => "./path/to/alternate/partial"
      #     :ssl      => TRue|False
      #     :partial_opts => {} #options to pass to partial()
      #       #Theses keys are deleted before being passed to RecapthaOptions
      #
      # @return [String]
      def captcha(threshold_name = nil, opts={})
        if threshold_name.is_a?(Hash)
          opts = threshold_name
          threshold_name = nil
        end
        
        # Has the thresholded resource been accessed 
        # if so 
        #   display captcha if currently_exceeded?
        # else
        #   dispaly captcha unless permit_another?
        #
        curr_threshold_key = threshold_key(threshold_name)
        
        if @checked_thresholds.member?(curr_threshold_key)
          @show_captcha = currently_exceeded?(threshold_name)
        else
          @show_captcha = !permit_another?(threshold_name)
        end
      
        # if it won't permit another, show the captcha
        if @show_captcha
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
end