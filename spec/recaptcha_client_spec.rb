include Merb::Threshold
describe RecaptchaClient do
  it 'should provide API_SERVER' do
    defined?(RecaptchaClient::API_SERVER).should ==('constant')
  end
  
  it 'should provide API_SSL_SERVER' do
    defined?(RecaptchaClient::API_SSL_SERVER).should ==('constant')
  end
  
  it 'should provide API_VERIFY_SERVER' do
    defined?(RecaptchaClient::API_VERIFY_SERVER).should ==('constant')
  end
  
  it 'should provide accessors for a public key' do
    RecaptchaClient.should respond_to :public_key
    RecaptchaClient.should respond_to :public_key=
    RecaptchaClient.public_key = "key"
    RecaptchaClient.public_key.should == "key"    
  end

  it 'should provide accessors for a private key' do  
    RecaptchaClient.should respond_to :private_key
    RecaptchaClient.should respond_to :private_key=
    RecaptchaClient.private_key = "key"
    RecaptchaClient.private_key.should == "key"
  end
  
  it 'should be able to submit a captcha response' do
    result = RecaptchaClient.solve("127.0.0.1","fake_challenge","fake_response")
    result.should be_instance_of(Array)
    result.first.should be(false)
    result.last.should == ("invalid_site-private-key")
  end
end