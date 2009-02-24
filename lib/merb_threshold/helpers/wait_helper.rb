module Merb
  module Threshold
    module Helpers
  
      ##
      # Display a wait message if the threshold has been exceeded
      #
      # @param threshold_name [~Symbol] key to look up
      #
      # @params opts [Hash] passed to partial as 'threshold_options'
      #     :partial_opts => {} #options to pass to partial()
      # @return [String]
      def wait(threshold_name = nil,opts={})
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
          @show_wait = currently_exceeded?(threshold_name)
        else
          @show_wait = !permit_another?(threshold_name)
        end

        # if it wont permit another show wait
        if @show_wait
          _wait_partial = opts.delete(:partial) || Merb::Plugins.config[:merb_threshold][:wait_partial]
          _partial_opts = opts.delete(:partial_opts) || {}
          _partial_opts.merge!({
            :seconds_to_wait => (waiting_period[threshold_key(threshold_name)] || 0)
          })
          partial(_wait_partial,_partial_opts)
        end
      end
  
    end
  end
end