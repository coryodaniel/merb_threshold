# Auto-generated ruby debug require       
require "ruby-debug"
Debugger.start
Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)

describe Merb::Threshold::Helpers do
  before do
    class CaptchaController < Merb::Controller
      register_threshold :index
      GhettoSessionStore = {}

      def session
        GhettoSessionStore[params[:session_id]] ||={}
        GhettoSessionStore[params[:session_id]]        
      end
      
      def index
        if !permit_access?(:index)
          @partial =File.join(File.expand_path("."),"lib/merb_threshold/templates/recaptcha_partial")
          captcha :partial => @partial, :partial_opts => {:format => :html}
        end
      end
    end
  end
  
  it 'should display a captcha if the threshold is exceeded' do
    @response = dispatch_to(CaptchaController, :index,{
      :session_id=>"display-captcha"
    })

    @response.should be_successful
    @response.body.should =~ /api.recaptcha/
  end
end