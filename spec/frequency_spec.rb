describe Frequency do  
  before(:each) do
    now = Time.now.to_i
    @history = [
      now - 301, 
      now - 121, 
      now - 61, 
      now - 31,
      now - 20
    ]
  end
  
  it 'should be able to initialize a frequency' do
    @freq = Frequency.new(5,30,:seconds)
    @freq.should be_an_instance_of(Frequency)
  end
  
  it 'should be able to initialize a frequency without the units' do
    @freq1 = Frequency.new 1, 30, :seconds
    @freq2 = Frequency.new 1, 30.seconds
    
    @freq1.interval.should be(@freq2.interval)
    @freq1.occurrence.should be(@freq2.occurrence)
    @freq1.units.should == @freq2.units
    @freq1.period.should be(@freq2.period)
  end
  
  it 'should create frequencies properly when using floats' do
    @freq = Frequency.new 1, 3.3, :minutes
    @freq.period.to_i == 198
  end

  it 'should cast the units automatically if not provided' do
    @freq = Frequency.new 5, 5.minutes
    @freq.period.should == 300
    @freq.interval.should == 5.0
    @freq.units.should == :minutes
  end
  
  it 'should cast the units automatically if not provided' do
    @freq = Frequency.new 5, 5.hours
    @freq.units.should == :hours
  end
  
  it 'should provide #to_s' do
    @freq = Frequency.new 5, 5.minutes
    @freq.to_s == "5 times per 5.0 minutes"
  end
  
  it 'should be able to load a list of events' do
    @freq = Frequency.new 5, 5, :minutes
    @freq.load @history
    
    @freq.events.length.should be(5)
  end
  
  it 'should be able to determine the rate of events over a period in seconds' do
    @freq = Frequency.new 1, 2, :minutes
    @freq.load @history
    
    # 3 fall within 2 minutes
    projected_rate = 3 / 120.0
    @freq.rate.should == projected_rate
  end
  
  it 'should always determine an event is not permissable when the period is zero' do
    @freq = Frequency.new 1, 0
    @freq2 = Frequency.new 1, 0, :seconds
    @freq3 = Frequency.new 1, 0, :minutes
    @freq4 = Frequency.new 0, 0
    
    @freq.permit?.should be(false)
    @freq2.permit?.should be(false)
    @freq3.permit?.should be(false)
    @freq4.permit?.should be(false)
  end
  
  it 'should be able to determine if an additional event is permissable' do
    @freq = Frequency.new 1, 2, :minutes
    @freq.load [Time.now.to_i - 30]
    @freq.permit?.should be(false)
    
    @freq2 = Frequency.new 5, 5, :minutes
    @freq2.load @history
    @freq2.permit?.should be(true)
  end
  
  it 'should be able to add a single event' do
    @freq = Frequency.new 5, 2.minutes
    @freq.add(Time.now.to_i).length.should be(1)
  end
  
  it 'should be able to determine if there is no wait for an available resource' do
    @freq = Frequency.new 5, 5.minutes
    @freq.load @history
    @freq.wait.should be(0)
  end
  
  it 'should be able to determine the wait time in seconds when unavailable' do
    @freq = Frequency.new 2, 1.minute
    @freq.load @history
    
    # Treshold is 1 minute
    # Oldest happend 31 seconds ago
    # in 29 more seconds it will fall out of the period (60 seconds)
    @freq.wait.should be(29)
  end
  
  it 'should be able to flush the currently loaded events' do
    @freq = Frequency.new 2, 1.minute
    @freq.load @history
    @freq.respond_to? :flush
    @freq.flush
    @freq.events.should be_empty
  end
  
  it 'should be able to load! events' do
    @freq = Frequency.new 2, 1.minute
    @freq.load @history
    @freq.load @history
    @freq.events.length.should be(10)
    @freq.load!([Time.now.to_i])
    @freq.events.length.should be(1)
  end
  
  it 'should be able to determine the wait tiem in seconds when unavailable (part 2)' do
    @freq = Frequency.new 2, 1.minute
    @freq.load @history
    @freq.flush
    
    @freq.add(Time.now.to_i)
    @freq.add(Time.now.to_i)
    
    @freq.wait.should be(60)
  end
end