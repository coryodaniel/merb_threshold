describe Merb::Controller do  
  before(:all) do
    class TestController < Merb::Controller
      def index; "Index"; end 
      def create; "Create"; end 
      def destroy; "Destroy"; end 
      def blog; "Blah blah"; end
      
      GhettoSessionStore = {}
      #Why is this ghetto session hack here?  Because I spent like an hour trying to figure
      # out how to get access to cookie based sessions in rspecs without starting a damn server
      # up and couldn't figure it out.  Feel free to 'fix' this.
      def session
        GhettoSessionStore[params[:session_id]] ||={}
        GhettoSessionStore[params[:session_id]]        
      end

    end
  end
  after(:each) do
    TestController._before_filters.clear
    TestController._threshold_map = {}
  end

  it 'should respond to #waiting_period' do
    TestController.new('').should respond_to(:waiting_period)
  end
  
  it 'should respond to TestController.threshold' do
    TestController.should respond_to(:threshold)
  end
  
  it 'should respond to #threshold' do
    TestController.new('').should respond_to(:threshold)
  end
  
  it 'should respond to #currently_exceeded?' do
    TestController.new('').should respond_to(:currently_exceeded?)
  end
  
  it 'should respond to #default_threshold_name' do
    TestController.new('').should respond_to(:default_threshold_name)
  end
  
  it 'should respond to #access_history' do
    TestController.new('').should respond_to(:access_history)
  end
    
  it 'should define THRESHOLD_OPTIONS' do
    defined?(Merb::Controller::THRESHOLD_OPTIONS).should == "constant"
    Merb::Controller::THRESHOLD_OPTIONS.should be_instance_of(Array)
  end
  
  it 'should raise an exception if mode :captcha is used and recaptcha is not enabled' do
    Merb::Plugins.config[:merb_threshold][:recaptca] = false
    lambda{
      TestController.threshold :create, :band => "stixx"      
    }.should raise_error(ArgumentError)
    Merb::Plugins.config[:merb_threshold][:recaptca] = true
  end
  it 'should raise an exception if an invalid option is passed' do
    lambda{
      TestController.threshold :create, :band => "stixx"
    }.should raise_error(ArgumentError)
  end
  
  it 'should define THRESHOLD_DEFAULTS' do
    defined?(Merb::Controller::THRESHOLD_DEFAULTS).should == "constant"
    Merb::Controller::THRESHOLD_DEFAULTS.should be_instance_of(Hash)
  end
  
  it 'should wrap calls to before filter with threshold' do
    class TestController
      threshold :index
    end
    TestController._before_filters.first.last[:only].member?("index")
    TestController._before_filters.first.first.should be_instance_of(Proc)
  end
  
  it 'should be able to determine if a captcha is valid or not' do
    TestController.threshold :index, :limit => [1,2.seconds]
    @response =     dispatch_to(TestController, :index,{:session_id=>"submitting_captcha"})
    @response =     dispatch_to(TestController, :index,{
      :session_id=>"submitting_captcha"
    })
    @response.currently_exceeded?("test_controller/index").should be(true)
    pending
  end
    
  it 'should be able to relax a (wait) threshold by waiting' do
    TestController.threshold :index, :mode => :wait, :limit => [1,2.seconds]
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout"})
    
    @response.currently_exceeded?("test_controller/index").should be(false)
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout"})
    @response.currently_exceeded?("test_controller/index").should be(true)
    
    @response.waiting_period["test_controller/index"].should be(2) 
    
    puts "Waiting a few seconds for timeout test..."
    sleep(4)
    
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout"})
    @response.currently_exceeded?("test_controller/index").should be(false)
  end
  
  it 'should be able to relax a (halt) threshold by waiting' do
    TestController.threshold :index, :mode => :halt, :limit => [1,2.seconds]
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
    
    @response.currently_exceeded?("test_controller/index").should be(false)
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
    @response.currently_exceeded?("test_controller/index").should be(true)
    
    @response.waiting_period["test_controller/index"].should be(2) 
    
    puts "Waiting a few seconds for timeout test..."
    sleep(4)
    
    @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
    @response.currently_exceeded?("test_controller/index").should be(false)
  end
  
  it 'should be able to throw(:halt) when a threshold is exceeded' do
    TestController.threshold :create, 
      :mode       => :halt, 
      :halt_with  => "Access Denied", 
      :limit      => [1,30.minutes]

    dispatch_to(TestController, :create,{:session_id=>"throw_halt_test"})

    @response =     dispatch_to(TestController, :create,{:session_id=>"throw_halt_test"})
    @response.body.should == "Access Denied"
  end
  
  it 'should set the wait time when the threshold has been exceeded and in wait mode' do
    TestController.threshold :create, :limit => [1,30.minutes], :mode => :wait
    @response = dispatch_to(TestController, :create, {:session_id => "wait_bitch"})
    @response = dispatch_to(TestController, :create, {:session_id => "wait_bitch"})

    @response.waiting_period["test_controller/create"].should be(30.minutes )
  end
  
  it 'should be able to determine if a threshold has been exceeded' do
    TestController.threshold :create, 
      :limit => [1,30.minutes]
    
    dispatch_to(TestController, :create, {:session_id => "threshold_exceed?"})
    @response = dispatch_to(TestController, :create, {:session_id => "threshold_exceed?"})

    @response.currently_exceeded?.should be(true)
  end
  
  it 'should be able to specify params as portions of the key in Controller.threshold' do
    TestController.threshold :blog, 
      :params => [:blog_id],
      :limit => [1,30.minutes]
      
    @response = dispatch_to(TestController, :blog, {
      :session_id => "params_in_key",
      :blog_id  => 35,
      :username => "awesome_user"
    })

    @response.access_history("test_controller/blog/35").should have(1).history
  end

  it 'should keep track of registered thresholds' do
    #make sure they dont bleed from one controller _thresholds to another
    # and that they dont contain parameterized keys
    pending
  end

  it 'should be able to take a named threshold' do
    pending
  end
  
  it 'should add an access time when the threshold has not been exceeded' do
    TestController.threshold :create, :limit => [30,1.minute]
    30.times do |access_counter|
      @response = dispatch_to(TestController, :create,{:session_id=>"record_access_to_resource"})
      @response.access_history("test_controller/create").should have(access_counter + 1).accesses
    end
  end
  
  it 'should not add an access time when the threshold has been exceeded' do
    TestController.threshold :create, :limit => [30,1.minute]
    30.times do |access_counter|
      @response = dispatch_to(TestController, :create,{:session_id=>"record_access_whilst_not_exceeded"})
      @response.access_history("test_controller/create").should have(access_counter + 1).accesses
    end
    
    @response = dispatch_to(TestController, :create,{:session_id=>"record_access_whilst_not_exceeded"})
    @response.threshold.should be(true)
    @response.access_history("test_controller/create").should have(30).accesses
  end
  
  it 'should consider a threshold exceeded always when not explicitly set by :limit' do
    TestController.threshold :create
    @controller = dispatch_to(TestController, :create,{:session_id=>"always_exceed_test"}) 
    @controller.threshold.should be(true)
  end
  
  it 'should apply the threshold to all actions when not specified' do
    TestController.threshold :limit => [10,30,:seconds]
    dispatch_to(TestController, :index,{:session_id=>"threshold_all_actions_test"})
    dispatch_to(TestController, :index,{
      :session_id=>"threshold_all_actions_test"
    }).access_history("test_controller/index").should have(2).accesses
    
    dispatch_to(TestController, :create,{
      :session_id=>"threshold_all_actions_test"
    }).access_history("test_controller/create").should have(1).access
    
    dispatch_to(TestController, :destroy,{:session_id=>"threshold_all_actions_test"})
    dispatch_to(TestController, :destroy,{
      :session_id=>"threshold_all_actions_test"
    }).access_history("test_controller/destroy").should have(2).accesses
  end
  
  it 'should only apply the threshold to the action(s) specified' do
    TestController.threshold :destroy, :mode => :wait
    TestController._before_filters.first.last[:only].length.should be(1)
    TestController._before_filters.first.last[:only].first.should == "destroy"
  end
  
  # Given same rule 2 per 30 seconds for index, create, destroy
  # each should maintain its own history of accesses
  #
  it 'when multiple actions are specified their access histories should be kept separate' do
    TestController.threshold :index, :create, :limit => [2, 30, :seconds]

    dispatch_to(TestController, :index,{:session_id=>"separate_history_test"})
    @response1=dispatch_to(TestController, :index,{:session_id=>"separate_history_test"})
    @response2=dispatch_to(TestController, :create,{:session_id=>"separate_history_test"})
    @response3=dispatch_to(TestController, :destroy,{:session_id=>"separate_history_test"})

    @response1.session[:merb_threshold_history]["test_controller/index"].should have(2).request
    @response2.session[:merb_threshold_history]["test_controller/create"].should have(1).request
    @response3.session[:merb_threshold_history]["test_controller/destroy"].should be_nil
  end
end