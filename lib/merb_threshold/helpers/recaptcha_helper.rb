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
          threshold_name = :"#{controller_name}/#{action_name}"
        end

        curr_threshold_key = threshold_key(threshold_name)
        
        # Has the thresholded resource been accessed during this request
        # if so 
        #   if it was relaxed
        #     dont show partial
        #   else
        #     show partial
        # else #resource wasn't access
        #   if permit_another?
        #     dont show partial
        #   else 
        #     show partial
        #       
        @show_captcha = if @relaxed_thresholds && @relaxed_thresholds.key?(curr_threshold_key)
          if @relaxed_thresholds[curr_threshold_key]
            false #dont show partial, it was relaxed
          else 
            true #show partial, threshold exceeded
          end
        else
          !will_permit_another?(threshold_name)
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