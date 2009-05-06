module Merb
  class Controller
    THRESHOLD_OPTIONS = [:limit, :params]
    THRESHOLD_DEFAULTS = {
      :limit      => [0,0.seconds],  #[Access, PerSecond]
      :params     => nil            #[:list, :of, :params, :to, :use, :in, :key]
    }
    
    #Use to keep an index of thresholds for looking up information
    # by name
    @@_threshold_map = Mash.new
    
    class << self
      ##
      # Registers a threshold for tracking
      #
      # @param threshold_name [~Symbol] name of threshold
      #
      # @param opts [Hash] Options on how to enforce threshold
      #   * :params     [Array[~Symbol]] Parameters to include in the threshold key
      #     :params => [:blog_id]
      #
      #   * :limit    [Array[Fixnum,Fixnum,Symbol]] number of access per time interval before
      #               threshold constraints are applied
      #               Default [0,0.seconds] #Always
      #     :limit => [2,5,:minutes]            #=> Frequency(2,5,:minutes)   2 per 5 minutes
      #     :limit => [1, 5.minutes]          #=> Frequency(1,5.minutes)   1 per 5 minutes
      #
      # @raises ArgumentError
      #
      # @api public
      #
      # @return [Array[~Symbol,Hash]]
      #   The name, opts it was registered as
      def register_threshold(threshold_name,opts={})
        if threshold_name.is_a?(Hash)
          raise ArgumentError, "Thresolds must be named!"
        end

        opts = THRESHOLD_DEFAULTS.merge(opts)

        opts.each_key do |key| 
          raise(ArgumentError,
            "You can only specify known threshold options (#{THRESHOLD_OPTIONS.join(', ')}). #{key} is invalid."
          ) unless THRESHOLD_OPTIONS.include?(key)
        end

        #register it
        @@_threshold_map[threshold_name] = opts
      end
      
      ##
      # A succinct wrapper to bulk register thresholds on actions and check access to those thresholds
      # in before filters.  This method will register the threshold and create the before filters.
      # 
      # The threshold names will be :"#{controller_name}/#{action_name}" when actions are given.
      #
      # If not actions are specified the threshold will be named for the controller.
      #
      # @param *args [~Array]
      #   args array for handling array of action names and threshold options
      #   Threshold queues are keyed with the controller & action name, so each
      #   action will have its own queue
      #
      # @param opts [Hash]
      #   * :limit    [Array[Fixnum,Fixnum,Symbol]] number of access per time interval before
      #               threshold constraints are applied
      #               Default [0,0.seconds] #Always
      #     :limit => [2,5,:minutes]            #=> Frequency(2,5,:minutes)   2 per 5 minutes
      #     :limit => [1, 5.minutes]          #=> Frequency(1,5.minutes)   1 per 5 minutes
      #
      #   * :halt_with  [String,Symbol,Proc] Halts the filter chain instead if the
      #                 threshold is in effect
      #                 takes same params as before filter's throw :halt
      #                 not specifying :halt_with when the mode is :halt
      #                 will result in: throw(:halt)
      #
      #   * :params     [Array[~Symbol]] Parameters to include in the threshold key
      #     :params => [:blog_id]
      #                 
      #   * :if / :unless - Passed to :if / :unless on before filter
      #
      # @note
      #   using the class method threshold_actions registers the threshold 
      #   (no need for a register_threshold statement) and creates a before filter
      #   for the given actions where the actual threshold check will take place
      #
      # @example
      #   Using threshold and the before filter it creates:
      # 
      #   #Create two action level thresholds
      #   class MyController < Application
      #     threshold_actions :index, :create, :limit => [5, 30.seconds]
      #
      #     #equivalent to:
      #     register_threshold :"my_controller/index", :limit => [5, 30.seconds]
      #     before(nil,{:only => [:index]}) do
      #       permit_access? :"my_controller/index"
      #     end
      #     register_threshold :"my_controller/create", :limit => [5, 30.seconds]
      #     before(nil,{:only => [:create]}) do
      #       permit_access? :"my_controller/create"
      #     end
      #
      #   #create a controller level threshold
      #   class MyController < Application
      #     threshold_actions :limit => [5000, 1.day]
      #     
      #     #equivalent to:
      #     register_threshold :my_controller, :limit => [5000, 1.day]
      #     before(nil,{}) do
      #       permit_access? :my_controller
      #     end
      #
      #   #create 1 action level threshold with :unless statement and halt
      #   class MyController < Application
      #   threshold_actions :search, :limit => [10, 5.minutes], 
      #     :unless => :is_admin?, 
      #     :halt_with => "Too many searches"
      #
      #   #equivalent to:
      #   register_threshold :"my_controller/search", :limit => [10, 5.minutes]
      #   before(nil,{:only => [:search], :unless => :is_admin?}) do
      #     if !permit_access?(:"my_controller/search")
      #       throw(:halt, "Too many searches")
      #     end
      #   end    
      #
      # @api public
      #
      def threshold_actions(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        thresholds_to_register = args

        #exctract :limit, :params
        threshold_opts  = {}
        threshold_opts[:limit]      = opts.delete(:limit) || [0, 0.seconds] #Always
        threshold_opts[:params]     = opts.delete(:params)

        halt_with                   = opts.delete(:halt_with)

        #get threshold supported before filter options
        filter_opts = {}
        filter_opts[:if]            = opts.delete(:if)      if opts[:if]
        filter_opts[:unless]        = opts.delete(:unless)  if opts[:unless]

        if thresholds_to_register.empty?
          # Register a controller level threshold
          self.register_threshold(controller_name,threshold_opts)

          self.before(nil,filter_opts) do
            if !permit_access?(controller_name) && !halt_with.nil?
              throw(:halt, halt_with)
            end
          end
        else
          #register a threshold for each action given
          thresholds_to_register.each do |action_to_register|
            tmp_threshold_name = :"#{controller_name}/#{action_name}"
            
            self.register_threshold(tmp_threshold_name,threshold_opts)

            self.before(nil, filter_opts.merge({:only => [action_to_register]})) do 
              if !permit_access?(tmp_threshold_name) && !halt_with.nil?
                throw(:halt,halt_with)
              end
            end
          end
        end
      end
    
    end #end class << self


    ##
    # Used for determining if a subsequent request would exceed the threshold
    #   
    # Good for protecting a post with a form or display captcha/wait before
    #   the threshold is exceeded
    #
    # @note See READEME: will_permit_another? vs is_currently_exceeded?
    #
    # @param threshold_name [~Symbol] The threshold to look up
    #
    # @api public
    #
    # @param [Boolean]
    def will_permit_another?(threshold_name=nil)
      threshold_name ||= :"#{controller_name}/#{action_name}"
      opts = @@_threshold_map[threshold_name]
      curr_threshold_key = threshold_key(threshold_name)

      # if opts[:limit] is not set that means the threshold hasn't been registered yet
      #   so permit access, the threshold will be registered once threshold() is called
      #   which is usually behind the post request this would be submitted to.
      if opts[:limit]
        frequency = if opts[:limit].is_a?(Array)
          Frequency.new(*opts[:limit])
        else
          opts[:limit].clone
        end
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
    # @note See READEME: will_permit_another? vs is_currently_exceeded?
    #
    # @param threshold_name [~Symbol]
    #   current threshold key to lookup
    #
    # @api public
    #
    # @return [Boolean]
    def is_currently_exceeded?(threshold_name=nil)
      threshold_name ||= :"#{controller_name}/#{action_name}"
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
    def threshold_key(threshold_name)  
      curr_threshold_key = threshold_name.to_s

      # create key to lookup threshold data from users session
      opts = @@_threshold_map[threshold_name]
      if opts[:params]
        opts[:params].each{ |param_key| curr_threshold_key += "/#{params[param_key]}" }
      end
      
      curr_threshold_key.to_sym
    end
                
    ##
    # Is access permitted to the threshold protected resource.
    #
    # @param threshold_name [~Symbol] Name of threshold to monitor
    #
    # @api public
    #
    # @returns [Boolean] was the access permitted?
    #
    def permit_access?(threshold_name=nil)
      threshold_name ||= :"#{controller_name}/#{action_name}"
      
      curr_threshold_key = threshold_key(threshold_name)
      opts = @@_threshold_map[threshold_name]
      
      if opts.nil?
        raise Exception, "Threshold (#{threshold_name}) was not registered"
      end
      
      # keep track of thresholds access and if they were relaxed
      @relaxed_thresholds ||= {}
      @relaxed_thresholds[curr_threshold_key] = false
          
      # may or may not be exceeded, but threshold was not relaxed
      frequency = if opts[:limit].is_a?(Array)
        Frequency.new(*opts[:limit])
      else
        opts[:limit].clone
      end
      
      frequency.load! access_history(curr_threshold_key)
      
      # Is this request permitted?
      if frequency.permit? && !is_currently_exceeded?(threshold_name)
        # if it is also in the exceeded list
        access_history(curr_threshold_key) << Time.now.to_i
        @relaxed_thresholds[curr_threshold_key] = true
      else
        # if request wasn't permitted and isn't already marked exceeded, mark it
        exceeded_thresholds << curr_threshold_key unless is_currently_exceeded?(threshold_name)
        
        #set the time until the treshold expires
        waiting_period[curr_threshold_key] = frequency.wait

        # try to relax threshold via captcha if enabled, then via waiting
        if Merb::Plugins.config[:merb_threshold][:recaptcha]
          @relaxed_thresholds[curr_threshold_key] = relax_via_captcha!(curr_threshold_key)
        end
        @relaxed_thresholds[curr_threshold_key] ||= relax_via_waiting! curr_threshold_key
      end

      #Only keep the last n number of access where n is frequency.occurence
      access_history(curr_threshold_key).replace frequency.current_events  
      
      return @relaxed_thresholds[curr_threshold_key]
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
    def relax_via_captcha!(curr_threshold_key)
      if params[:recaptcha_challenge_field] && params[:recaptcha_response_field]
        did_solve, captcha_error = ::RecaptchaClient.solve(request.remote_ip,
          params[:recaptcha_challenge_field],
          params[:recaptcha_response_field]
        )
      
        if did_solve
          relax_threshold(curr_threshold_key)
        else
          @captcha_error = captcha_error
        end
      
        did_solve
      else #no captcha data provided
        false
      end
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
    def relax_via_waiting!(curr_threshold_key)
      last_access   = access_history(curr_threshold_key).last
      time_to_wait  = (waiting_period[curr_threshold_key] || 0)
      
      #if there was no previous acces, this didn't relax from waiting
      return false if last_access.nil?
      
      did_relax = (Time.now.to_i > (last_access + time_to_wait))
      
      relax_threshold(curr_threshold_key) if did_relax
      
      did_relax
    end
    
    ##
    # Resets all tracked attributes on a threshold
    #
    # @param curr_threshold_key [~Symbol] they key to clear
    #
    def relax_threshold(curr_threshold_key)
      exceeded_thresholds.delete curr_threshold_key
      access_history(curr_threshold_key).clear
      waiting_period.delete(curr_threshold_key)
    end
    
  end # end Merb::Controller
end # end Merb