describe Per do
  it 'should provide the per method' do
    3.should respond_to :per
  end
  
  it 'should return a frequency object' do
    3.per(30.seconds).should be_instance_of(Frequency)
  end
end