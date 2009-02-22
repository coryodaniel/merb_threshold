module Merb
  module GlobalHelpers    
    
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

      curr_thresh_key = threshold_key(threshold_name)

      # if it wont permit another show wait
      if permit_another? threshold_name
        _wait_partial = opts.delete(:partial) || Merb::Plugins.config[:merb_threshold][:wait_partial]
        _partial_opts = opts.delete(:partial_opts) || {}
        _partial_opts.merge!({
          :seconds_to_wait => (waiting_period[curr_thresh_key] || 0)
        })
        partial(_wait_partial,_partial_opts)
      end
    end
    
  end
end