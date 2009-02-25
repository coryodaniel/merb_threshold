# Auto-generated ruby debug require       
require "ruby-debug"
Debugger.start
Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
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

  it 'should respond to TestController.register_threshold' do
    TestController.should respond_to(:register_threshold)
  end

  it 'should respond to TestController.check_threshold' do
    TestController.should respond_to(:check_threshold)
  end
  
  it 'should respond to #threshold' do
    TestController.new('').should respond_to(:check_threshold)
  end
  
  it 'should respond to #is_currently_exceeded?' do
    TestController.new('').should respond_to(:is_currently_exceeded?)
  end
  
  it 'should respond to #access_history' do
    TestController.new('').should respond_to(:access_history)
  end
    
  it 'should define THRESHOLD_OPTIONS' do
    defined?(Merb::Controller::THRESHOLD_OPTIONS).should == "constant"
    Merb::Controller::THRESHOLD_OPTIONS.should be_instance_of(Array)
  end

  it 'should raise an exception if a threshold is not named' do
    lambda{
      TestController.register_threshold :limit => 1.per(30.seconds)
    }.should raise_error(ArgumentError)
  end
  
  it 'should raise an exception if an invalid option is passed' do
    lambda{
      TestController.register_threshold :create, :band => "stixx"
    }.should raise_error(ArgumentError)
  end
  
  it 'should define THRESHOLD_DEFAULTS' do
    defined?(Merb::Controller::THRESHOLD_DEFAULTS).should == "constant"
    Merb::Controller::THRESHOLD_DEFAULTS.should be_instance_of(Hash)
  end
  
  it 'should wrap calls to before filter with threshold' do
    class TestController
      check_threshold :index
    end
    TestController._before_filters.first.last[:only].member?("index")
    TestController._before_filters.first.first.should be_instance_of(Proc)
  end
  
  it 'should consider a captch invalid if the challenge was not submitted' do
    pending
  end
  
  it 'should be able to determine if a captcha is valid or not' do
    TestController.check_threshold :index, :limit => 1.per(1.week)
    @response =     dispatch_to(TestController, :index,{:session_id=>"submitting_captcha"})
    
    # Logic here is that recaptcha, guarantees when a captcha is solved, just need to confirm
    # that the api can be contacted
    @response =     dispatch_to(TestController, :index,{
      :session_id => "submitting_captcha",
      :recaptcha_challenge_field => "bad challenge",
      :recaptcha_response_field => "bad response"
    })

    @response.is_currently_exceeded?(:index).should be(true)
    @response.instance_variable_get("@captcha_error").should_not be(nil)
  end
    
  it 'should be able to relax a threshold by waiting' do
    unless ENV['SKIP_WAIT']
      TestController.check_threshold :index, :limit => 1.per(2.seconds)
      @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout"})
    
      @response.is_currently_exceeded?(:index).should be(false)
      @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout"})
      @response.is_currently_exceeded?(:index).should be(true)
    
      @response.waiting_period[:index].should be(2) 
    
      puts "Waiting a few seconds for timeout test..."
      sleep(4)
    
      @response =     dispatch_to(TestController, :index,{
        :session_id=>"allow_wait_timeout",
        :debug => "true"
      })
      @response.is_currently_exceeded?(:index).should be(false)
    end
  end
  
  it 'should be able to relax a threshold that halts by waiting' do
    unless ENV['SKIP_WAIT']
      TestController.check_threshold :index, :limit => [1,2.seconds], :halt_with => "Too many requests!"
      @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
    
      @response.is_currently_exceeded?(:index).should be(false)
      @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
      @response.is_currently_exceeded?(:index).should be(true)
    
      @response.waiting_period[:index].should be(2) 
    
      puts "Waiting a few seconds for timeout test..."
      sleep(4)
    
      @response =     dispatch_to(TestController, :index,{:session_id=>"allow_wait_timeout_w_halt"})
      @response.is_currently_exceeded?(:index).should be(false)
    end
  end
  
  it 'should be able to throw(:halt) when a threshold is exceeded' do
    TestController.check_threshold :create, 
      :halt_with  => "Access Denied", 
      :limit      => [1,30.minutes]

    dispatch_to(TestController, :create,{:session_id=>"throw_halt_test"})

    @response =     dispatch_to(TestController, :create,{:session_id=>"throw_halt_test"})
    @response.body.should == "Access Denied"
  end
  
  it 'should set the wait time when the threshold has been exceeded and in wait mode' do
    TestController.check_threshold :create, :limit => [1,30.minutes]
    @response = dispatch_to(TestController, :create, {:session_id => "wait_bitch"})
    @response = dispatch_to(TestController, :create, {:session_id => "wait_bitch"})

    @response.waiting_period[:create].should be(30.minutes)
  end
  
  it 'should be able to determine if a threshold has been exceeded' do
    TestController.check_threshold :create, :limit => 1.per(30.minutes)
    
    dispatch_to(TestController, :create, {:session_id => "threshold_exceed?"})
    @response = dispatch_to(TestController, :create, {:session_id => "threshold_exceed?"})

    @response.is_currently_exceeded?(:create).should be(true)
  end
  
  it 'should be able to specify params as portions of the key in Controller.threshold' do
    TestController.check_threshold :blog, 
      :params => [:blog_id],
      :limit => [1,30.minutes]
      
    @response = dispatch_to(TestController, :blog, {
      :session_id => "params_in_key",
      :blog_id  => 35,
      :username => "awesome_user"
    })

    @response.access_history(:"blog/35").should have(1).history
  end
  
  it 'should add an access time when the threshold has not been exceeded' do
    TestController.check_threshold :create, :limit => [30,1.minute]
    30.times do |access_counter|
      @response = dispatch_to(TestController, :create,{:session_id=>"record_access_to_resource"})
      @response.access_history(:create).should have(access_counter + 1).accesses
    end
  end
  
  it 'should not add an access time when the threshold has been exceeded' do
    TestController.check_threshold :create, :limit => [30,1.minute]
    30.times do |access_counter|
      @response = dispatch_to(TestController, :create,{:session_id=>"record_access_whilst_not_exceeded"})
      @response.access_history(:create).should have(access_counter + 1).accesses
    end
    
    @response = dispatch_to(TestController, :create,{:session_id=>"record_access_whilst_not_exceeded"})
    @response.check_threshold(:create).should be(false)
    @response.access_history(:create).should have(30).accesses
  end
  
  it 'should be able to determine if it can permit another access' do
    TestController.check_threshold :index, :limit => 2.per(30.seconds)
    @response = dispatch_to(TestController, :index,{:session_id=>"default_to_action_name"})
    @response.will_permit_another?(:index).should be(true)
    @response = dispatch_to(TestController, :index,{:session_id=>"default_to_action_name"})
    @response.will_permit_another?(:index).should be(false)
  end
  
  it 'should check the threshold with the action name if not provided' do
    pending
    #TestController.check_threshold :index, :limit => 1.per(30.minutes)
    #@response = dispatch_to(TestController, :index,{:session_id=>"default_to_action_name"})
    #need an action to call check_threshold
  end
  
  it 'should captcha everytime if the :limit is not set' do
    pending
  end
  
  it 'should never wait if the :limit is not set' do
    pending
  end
    
  it 'should apply the threshold to the controller when not specified' do
    TestController.check_threshold :limit => [10,30,:seconds]
    dispatch_to(TestController, :index,{
      :session_id=>"threshold_all_actions_test"
    }).access_history(:test_controller).should have(1).accesses
    
    dispatch_to(TestController, :create,{
      :session_id=>"threshold_all_actions_test"
    }).access_history(:test_controller).should have(2).accesses
    
    dispatch_to(TestController, :destroy,{
      :session_id=>"threshold_all_actions_test"
    }).access_history(:test_controller).should have(3).accesses
  end
  
  it 'should only apply the threshold to the action(s) specified' do
    TestController.check_threshold :destroy
    TestController._before_filters.first.last[:only].length.should be(1)
    TestController._before_filters.first.last[:only].first.should == "destroy"
  end
  
  # Given same rule 2 per 30 seconds for index, create, destroy
  # each should maintain its own history of accesses
  #
  it 'when multiple actions are specified their access histories should be kept separate' do
    TestController.check_threshold :index, :create, :limit => [2, 30, :seconds]

    dispatch_to(TestController, :index,{:session_id=>"separate_history_test"})
    @response1=dispatch_to(TestController, :index,{:session_id=>"separate_history_test"})
    @response2=dispatch_to(TestController, :create,{:session_id=>"separate_history_test"})
    @response3=dispatch_to(TestController, :destroy,{:session_id=>"separate_history_test"})

    @response1.session[:merb_threshold_history][:index].should have(2).request
    @response2.session[:merb_threshold_history][:create].should have(1).request
    @response3.session[:merb_threshold_history][:destroy].should be_nil
  end
end