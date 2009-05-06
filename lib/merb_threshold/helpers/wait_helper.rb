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
        @show_wait = if @relaxed_thresholds && @relaxed_thresholds.key?(curr_threshold_key)
          if @relaxed_thresholds[curr_threshold_key]
            false #dont show partial, it was relaxed
          else 
            true #show partial, threshold exceeded
          end
        else #wasn't accessed, will it permit another?
          !will_permit_another?(threshold_name)
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