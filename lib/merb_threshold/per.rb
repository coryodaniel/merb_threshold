
module Merb
  module Threshold
    # Add support for doing
    # :limit => 1.per(30.seconds)
    # :limit => 1.per(50, :minutes)
    module Per
      def per(period, units = nil)
        Frequency.new(self,period,units)
      end
    end
  end
end