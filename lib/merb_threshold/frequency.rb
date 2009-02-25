module Merb
  module Threshold

    ##
    #
    # @note
    #   * time is treated as relative from 'now' 
    #   * nowhere are events sorted within this class so they should
    #     be added in their proper order
    #   * Why? its easy to do this from the controller naturally since time is linear (right?)
    #       and its faster not having to worry about sorting whenever an occurrence is added
    #
    class Frequency      
      attr_reader :interval, :occurrence, :units, :period, :events
  
      # Frequency.new(5, 30, :seconds)  =>  "5 times per 30 seconds"
      # Frequency.new(1, 3.minutes)     =>  "1 time per 180 seconds"
      def initialize(occ,int,unts = nil)
        @occurrence   = occ
        @interval     = int
    
        # All test are done with the period (reduced to seconds)
        # 50.minutes #=> 50.send :minutes => 3000 seconds        
        if unts
          @period       = interval.send unts
          @units = unts
        else #no units default :seconds
          @period       = interval
          cast_units
        end
        
        #If the period is zero, never permit?
        if period == 0
          @occurrence = 0
        end
      end
    
      ##
      # tests if the frequency would permit the additional occurence or if it
      #   would exceed the frequency.  Histories can be loaded with frequency#load
      #
      # @see #load
      #
      # @return [Boolean]
      #
      def permit?
        (current_events.length < occurrence)
      end

      ##
      # How long until the resource is freely available
      #
      # @return [~Numeric]
      def wait
        num_evts = current_events.length
        if num_evts == 0 || num_evts < occurrence
          return 0
        else #How long until the oldest falls off?
          # originally had now - period > @mm.first but +1 all over the place was
          #   retareded:
          # Want: now - period >= @mm.first
          #   now - period + x == @mm.first
          #   => x == @mm.first + period - now
          return (current_events.first + period - Time.now.to_i)
        end
      end

      ##
      # Loads a history of events
      # 
      # @param evts [~Array[Fixnum]] list of timestamps
      #
      # @note
      #   Should be loaded presorted (threshold should always stored sorted min=>high)
      #   an array is used rather than a set because duplicates may be needed 
      #   (concurrent access times)
      #
      def load(evts)
        @events ||= []
        @events += evts
      end
      
      ##
      # clears current events and sets
      # 
      # @param evts [~Array[Fixnum]] list of timestamps
      #
      # @see #load
      #
      #
      def load!(evts)
        @events = evts
      end
      
      ##
      # flushes the events array
      #
      def flush
        @events = []
      end
      
      ##
      # adds a single event, this always adds and does not perform a permit? first
      # @param evt [Fixnum] Timestamp
      #
      # @return [Array[Fixnum]]
      def add(evt)
        @events ||= []
        @events << evt
        @events
      end
  
      ##
      # The rate of occurences in seconds
      #   returns the frequency for events that happened over period
      #
      # @see #events
      # @see #load
      # @see #period
      #
      # @return [~Numeric]
      #
      def rate
        current_events.length / period.to_f
      end
                    
      ##
      # Casts frequency units when not specified
      #
      def cast_units
        case @interval
        when 0..120     # :seconds
          @units = (@interval != 1 ? :seconds : :second)
        when 121..3600  # :minutes
          @interval = @interval / 60.0
          @units = (@interval != 1 ? :minutes : :minute)
        else            # :hours
          @interval = @interval / 3600.0
          @units = (@interval != 1 ? :hours : :hour)
        end
      end        
              
      ##
      # Describe the frequency
      #
      # @return [String]
      def to_s
        @to_s ||= "#{occurrence} time#{'s' if occurrence != 1} per #{interval} #{units}"
      end
    
      ##
      # Get list of events for current period
      #
      # @return [Array[Fixnum]]
      #
      def current_events
        if @events
          @events.find_all{ |evt| evt >= (Time.now.to_i - period) }
        else
          @events ||= []
        end
      end
    end
  end
end