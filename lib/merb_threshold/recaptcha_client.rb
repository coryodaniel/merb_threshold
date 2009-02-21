require 'net/http'

module Merb
  module Threshold
    class RecaptchaClient
      API_SERVER        = "http://api.recaptcha.net"
      API_SSL_SERVER    = "https://api-secure.recaptcha.net"
      API_VERIFY_SERVER = "http://api-verify.recaptcha.net"
      
      def self.public_key
        @@public_key
      end
      def self.public_key=(key)
        @@public_key = key
      end
      def self.private_key
        @@private_key
      end
      def self.private_key=(key)
        @@private_key = key
      end
      
      ##
      # Attempt to solve the captcha
      #
      # @param ip [String] remote ip address
      # @param challenge [String] captcha challenge
      # @param response [String] captcha response
      #
      # @return [Array[Boolean,String]]
      #
      def self.solve(ip,challenge,response)
        response = Net::HTTP.post_form(URI.parse(API_VERIFY_SERVER + '/verify'),{
          :privatekey => @@private_key,
          :remoteip   => ip,         #request.remote_ip,
          :challenge  => challenge,  #params[:recaptcha_challenge_field],
          :response   => response    #params[:recaptcha_response_field]
        })
        
        answer, error = response.body.split.map { |s| s.chomp }

        [ !!(answer=='true'), error ]
      end

    end
  end
end