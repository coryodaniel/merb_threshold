describe Merb::GlobalHelpers do
  before do
    class CaptchaController < Merb::Controller
      GhettoSessionStore = {}
      def session
        GhettoSessionStore[params[:session_id]] ||={}
        GhettoSessionStore[params[:session_id]]        
      end
      
      def index
        if threshold
          captcha :partial => File.join(
            File.expand_path("."),"lib/merb_threshold/templates/recaptcha_partial"
          ), :partial_opts => {:format => :html}
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