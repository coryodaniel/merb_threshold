describe Merb::GlobalHelpers do
  before do
    class WaitController < Merb::Controller
      GhettoSessionStore = {}
      def session
        GhettoSessionStore[params[:session_id]] ||={}
        GhettoSessionStore[params[:session_id]]        
      end
      
      def index
        if threshold :limit => [1,30.seconds], :mode => :wait
          wait :partial => File.join(
            File.expand_path("."),"lib/merb_threshold/templates/wait_partial"
          ), :partial_opts => {:format => :html}
        end
      end
    end
  end
  
  it 'should display a wait message if the threshold is exceeded' do
    dispatch_to(WaitController, :index,{:session_id=>"display-wait-msg"})
    @response = dispatch_to(WaitController, :index,{
      :session_id=>"display-wait-msg"
    })
    
    @response.should be_successful
    @response.body.should =~ /This resource will be available/
  end
end