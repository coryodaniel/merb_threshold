module Merb
  class Controller
    THRESHOLD_OPTIONS = [:if, :unless, :mode, :exceed, :limit, :halt_with, :params]
    THRESHOLD_DEFAULTS = {
      :mode       => :captcha,
      :limit      => [0,0.seconds]
    }
    
    #Use to keep an index of thresholds for looking up information
    # by name
    class_inheritable_accessor :_threshold_map
    self._threshold_map = {}        


    ##
    # Used for determining if a subsequent request would exceed the threshold
    #   
    # Good for protecting a post with a form or display captcha/wait before
    #   the threshold is exceeded
    #
    # @note See READEME: permit_another? vs currently_exceeded?
    #
    # @param threshold_name [~Symbol] The threshold to look up
    #
    # @api public
    #
    # @param [Boolean]
    def permit_another?(threshold_name=nil)
      threshold_name ||= default_threshold_name
      
      opts = get_threshold_options(threshold_name)
      curr_threshold_key = threshold_key(threshold_name)

      # if opts[:limit] is not set that means the threshold hasn't been registered yet
      #   so permit access, the threshold will be registered once threshold() is called
      #   which is usually behind the post request this would be submitted to.
      if opts[:limit]
        frequency = Frequency.new(*opts[:limit])
        frequency.load! access_history(curr_threshold_key)
    
        frequency.permit?
      else
        true
      end
    end
    
    ##
    # Is the threshold currenlty exceeded either by this request or a previous one
    #
    # Good for redirecting access during the current request
    #
    # @note See READEME: permit_another? vs currently_exceeded?
    #
    # @param threshold_name [~Symbol]
    #   current threshold key to lookup
    #
    # @api public
    #
    # @return [Boolean]
    def currently_exceeded?(threshold_name=nil)
      curr_threshold_key = threshold_key(threshold_name)
      exceeded_thresholds.member? curr_threshold_key
    end
    
    
    ##
    # Shortcut to session[:merb_threshold_waiting_period]
    #
    # @note
    #   values stored in here are keyed with #threshold_key
    #   waiting_period[your_threshold_name] is not guaranteed to work instead use
    #   waiting_period[threshold_key(your_threshold_name)]
    #
    # @see #threshold_key
    #
    # @api semi-public
    #
    # @return [Hash]
    def waiting_period
      session[:merb_threshold_waiting_period] ||= {}
    end
        
    ##
    # get the key representation of the threshold name.  Used to store data
    #   in session.  This should be used whenever accessing data stored in the session
    #   hash.
    #
    # @note
    #   This is needed to support Params values as a part of the threshold name
    #
    # @param threshold_name [~Symbol] name of the threshold to get key for
    #
    # @api semi-public
    #
    # @return [~Symbol]
    def threshold_key(threshold_name = nil)  
      curr_threshold_key = threshold_name || default_threshold_name

      # create key to lookup threshold data from users session
      opts = get_threshold_options(threshold_name)
      if opts[:params]
        opts[:params].each{ |param_key| curr_threshold_key += "/#{params[param_key]}" }
      end
      
      curr_threshold_key
    end
    
    ##
    # Provides a default threshold key for thresholding methods if not provided
    #
    def default_threshold_name
      @default_threshold_name ||= (controller_name + '/' + action_name)
    end
            
    ##
    # Controls access to a resource via thresholding.  
    #   Returns whether the request was restricted by the threshold
    #
    # @param threshold_name [~Symbol] Name of threshold to monitor
    #
    # @param opts [Hash] Options on how to enforce threshold
    #   * :mode     [Symbol]    :captcha, :wait
    #               Action to take when threshold is exceeded:
    #                 :captcha  - displays captcha
    #                 :wait     - display wait message / resource busy
    #               Default :captcha
    #
    #   * :params     [Array[~Symbol]] Parameters to include in the threshold key
    #     :params => [:blog_id]
    #
    #   * :limit    [Array[Fixnum,Fixnum,Symbol]] number of access per time interval before
    #               threshold constraints are applied
    #               Default [0,0.seconds] #Always
    #     :limit => [2,5,:minutes]            #=> Frequency(2,5,:minutes)   2 per 5 minutes
    #     :limit => [1, 5.minutes]          #=> Frequency(1,5.minutes)   1 per 5 minutes
    #
    # @note
    #   * :mode => :halt is only an options of the class level threshold method, since it HALTS
    #       filter chains
    #
    # @api public
    #
    # @returns [Boolean]
    #
    def threshold(threshold_name = nil, opts={})      
      threshold_name, opts  = register_threshold threshold_name, opts
      
      curr_threshold_key = threshold_key threshold_name
            
      # Was this resource previously exceeded
      if currently_exceeded? threshold_name
        case opts[:mode]
        when :captcha
          @relax_threshold = solve_with_captcha! curr_threshold_key
        when :wait
          @relax_threshold = relax_from_waiting! curr_threshold_key
        when :halt #thresholds can only be relaxed when :halt by waiting
          @relax_threshold = relax_from_waiting! curr_threshold_key
        end
      end
      
      # the user WAS exceeded, but relaxed the threshold by waiting or captcha'ing
      if @relax_threshold
        access_history(curr_threshold_key) << Time.now.to_i
        return true
      else
        # may or may not be exceeded, but threshold was not relaxed
        frequency = Frequency.new(*opts[:limit])
        frequency.load! access_history(curr_threshold_key)

        request_permitted = frequency.permit?
        
        if request_permitted # Log access
          access_history(curr_threshold_key) << Time.now.to_i
        end
        
        #Only keep the last n number of access where n is frequency.occurence
        access_history(curr_threshold_key).replace frequency.current_events
    
        if !request_permitted
          # if request wasn't permitted and isn't already marked exceeded, mark it
          exceeded_thresholds << curr_threshold_key unless currently_exceeded?(threshold_name)
          
          #set the wait time if its a waitable mode
          if opts[:mode] == :wait || opts[:mode] == :halt
            waiting_period[curr_threshold_key] = frequency.wait 
          end
        end
    
        return !request_permitted
      end
    end
    
    ##
    # A succinct wrapper for before filters to create threshold on a view
    #   The views threshold uses the same method as the partial level (threshold)
    #   except that the name is left nil (which defaults to controller/action name)
    #
    # @param *args [~Array]
    #   args array for handling array of action names and threshold options
    #   Threshold queues are keyed with the controller & action name, so each
    #   action will have its own queue
    #
    # @param threshold_options [Array]
    #   Array of actions to apply threshold; passed to before filters :only option
    #
    # @param opts [Hash]
    #   * :mode     [Symbol]    :captcha, :wait, :halt
    #               Action to take when threshold is exceeded:
    #                 :captcha  - displays captcha
    #                 :wait     - display wait message / resource busy
    #                 :halt     - halts begin filter chain
    #               Default :captcha
    #
    #   * :limit    [Array[Fixnum,Fixnum,Symbol]] number of access per time interval before
    #               threshold constraints are applied
    #               Default [0,0.seconds] #Always
    #     :limit => [2,5,:minutes]            #=> Frequency(2,5,:minutes)   2 per 5 minutes
    #     :limit => [1, 5.minutes]          #=> Frequency(1,5.minutes)   1 per 5 minutes
    #
    #   * :halt_with  [String,Symbol,Proc] Halts the filter chain instead of
    #                 displaying a captcha
    #                 This option is only used when :mode => :halt
    #                 takes same params as before filter's throw :halt
    #                 not specifying :halt_with when the mode is :halt
    #                 will result in: throw(:halt)
    #
    #   * :params     [Array[~Symbol]] Parameters to include in the threshold key
    #     :params => [:blog_id]
    #                 
    #   * :if / :unless - Passed to :if / :unless on before filter
    #
    # @example
    #   Using threshold and the before filter it creates:
    #
    #   class MyController < Application
    #     #Captcha every time :index is accessed
    #
    #     threshold :index
    #     # Equivalent to:
    #     before nil, :only => [:index] do
    #       threshold
    #     end
    #
    #   class MyController < Application
    #     #Captcha every time controller is accessed
    #     threshold
    #     # Equivalent to:
    #     before { threshold }
    #
    #   class MyController < Application
    #     # Allow 3 uses per 2 minutes, beyond that tell the user they must
    #     #   wait 2 minutes
    #
    #     threshold :index, :create, :mode => :wait, :limit => [3, 2.minutes]
    #
    #     # Equivalent to:
    #     before nil, :only => [:index, :create] do
    #       threshold :mode => :wait, :limit => [3, 2.minutes]
    #     end
    #
    #   class MyController < Application
    #     # Allow the access of :create 1 per 30 seconds, beyond that captcha user
    #     threshold :create, :limit => [1, 30.seconds]
    #
    #     # Equivalent to:
    #     before nil, :only => [:create] do
    #       threshold :limit => [1, 30.seconds]
    #     end
    #
    #   class MyController < Application
    #     #captcha the user on every access of this controller except
    #     # for the given piece of logic
    #     threshold :unless => lambda{ ... cool logic here ... }
    #
    #     # Equivalent to:
    #     before nil, :unless => lambda{... cool logic...} do
    #       threshold
    #     end
    # @api public
    #
    def self.threshold(*args)
      opts = args.last.is_a?(Hash) ? args.pop : {}
            
      #exctract :mode, :limit, :params
      threshold_opts  = {}
      threshold_opts[:mode]       = opts.delete(:mode)
      threshold_opts[:limit]      = opts.delete(:limit) || [0, 0.seconds]#Always
      threshold_opts[:params]     = opts.delete(:params)
      
      halt_with                   = opts.delete(:halt_with)
      
      opts[:only] = args unless args.empty?
      
      self.before(nil, opts) do 
        # only care if the mode is :halt, otherwise the view will display :wait or :captcha
        if threshold(default_threshold_name,threshold_opts) && threshold_opts[:mode] == :halt
          throw(:halt,halt_with)
        end
      end
      
    end
    
    ##
    # Looks up the users access history
    #
    # @param curr_threshold_key [~Symbol]
    #   current threshold key to lookup
    #
    # @note
    #   this is a shortcut to the session hash, thus it needs the threshold_key not the 
    #   threshold_name
    #
    # @see #threshold_key
    #
    # @api private
    #
    # @return [Array[Fixnum]]
    def access_history(curr_threshold_key)        
      session[:merb_threshold_history] ||= {}
      session[:merb_threshold_history][curr_threshold_key] ||= []
      session[:merb_threshold_history][curr_threshold_key]
    end
    
    ##
    # Gets a list of exceeded thresholds
    #
    # @note
    #   this is a shortcut to the session hash, thus it needs the threshold_key not the 
    #   threshold_name
    #
    # @see #threshold_key
    #
    # @api private
    #
    # @return [Array[~Symbol]]
    #
    def exceeded_thresholds
      session[:merb_threshold_exceeded_thresholds] ||= []
      session[:merb_threshold_exceeded_thresholds]      
    end
    
    protected
        
    ##
    # Registers a threshold's options for lookup later
    #
    # @param threshold_name [~Symbol] name of threshold
    #
    # @param opts [Hash] options to tie to it
    #
    # @raises ArgumentError
    #
    # @api private
    #
    # @return [Array[~Symbol,Hash]]
    #   The name, opts it was registered as
    def register_threshold(threshold_name,opts={})
      if threshold_name.is_a?(Hash) #unnamed thresholds end up with opts as first param
        opts            = threshold_name
        threshold_name  = default_threshold_name
      end
      
      threshold_name ||= default_threshold_name
      
      unless self._threshold_map.key?(threshold_name)
        #register it
        self._threshold_map[threshold_name] = opts 
        
        opts = THRESHOLD_DEFAULTS.merge(opts)

        if opts[:mode] == :captcha && !Merb::Plugins.config[:merb_threshold][:recaptcha]
          raise ArgumentError, "To use threshold mode :captcha you must set Merb::Plugins.config[:merb_threshold][:recaptcha] = true"
        end
        
        opts.each_key do |key| 
          raise(ArgumentError,
            "You can only specify known threshold options (#{THRESHOLD_OPTIONS.join(', ')}). #{key} is invalid."
          ) unless THRESHOLD_OPTIONS.include?(key)
        end
        
        self._threshold_map[threshold_name] = opts
      end
      
      [threshold_name, self._threshold_map[threshold_name]]
    end
    
    ##
    # retrieves the options the threshold was initially registerd with
    #
    # @param threshold_name [~Symbol] name of threshold
    #
    # @api private
    #
    # @return [Hash]
    #
    def get_threshold_options(threshold_name)
      self._threshold_map[threshold_name] || {}
    end
    
    ##
    # Determines if the user's request solved the captcha
    #
    # If the threshold was relaxed, this method resets exceeded threshold and access history
    #   for this key
    #
    # @param curr_threshold_key [~Symbol]
    #   current threshold key to lookup
    #
    # @note
    #   this deals primarily with the session hash, thus it needs the threshold_key not the 
    #   threshold_name
    #
    # @see #threshold_key
    #
    # @api private
    #
    # @return [Boolean]
    def solve_with_captcha!(curr_threshold_key)
      did_solve, captcha_error = ::RecaptchaClient.solve(request.remote_ip,
        params[:recaptcha_challenge_field],
        params[:recaptcha_response_field]
      )
      
      if did_solve
        exceeded_thresholds.delete curr_threshold_key
        access_history(curr_threshold_key).clear
      else
        @captcha_error = captcha_error
      end
      
      did_solve
    end
    
    ##
    # Determines if the threshold was relaxed by the user waiting
    #
    # If the threshold was relaxed, this method resets exceeded threshold, wait time and access history
    #   for this key
    #
    # @param curr_threshold_key [~Symbol]
    #   current threshold key to lookup
    #
    # @note
    #   this deals primarily with the session hash, thus it needs the threshold_key not the 
    #   threshold_name
    #
    # @see #threshold_key
    #
    # @api private
    #
    # @return [Boolean]
    #
    def relax_from_waiting!(curr_threshold_key)
      last_access   = access_history(curr_threshold_key).last
      time_to_wait  = (waiting_period[curr_threshold_key] || 0)

      did_relax = (Time.now.to_i > (last_access + time_to_wait))
      
      if did_relax
        exceeded_thresholds.delete curr_threshold_key
        access_history(curr_threshold_key).clear
        waiting_period.delete(curr_threshold_key)
      end
      
      did_relax
    end
    
  end # end Merb::Controller
end # end Merb