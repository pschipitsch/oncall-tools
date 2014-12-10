require 'twilio-ruby'
require 'httparty'
require 'date'

module OnCall
  include Twilio

  class PagerDuty

    # Error codes
    PD_ERROR_GET_SCHEDULE_BY_ID = 2
    PD_ERROR_GET_USER_BY_ID     = 3
    PD_ERROR_GET_USER_PHONE     = 4

    def initialize(subdomain, auth_token)
      @subdomain    = subdomain
      @auth_token   = auth_token
      @token_string = "Token token=#{@auth_token}"
    end

    def get_schedule_by_id(id)
      now      = DateTime.now
      endpoint = "https://#{@subdomain}.pagerduty.com/api/v1/schedules/#{id}/entries?since=#{now}&until=#{now}"

      http_get_json(endpoint)

    rescue => e
      puts e.message
      puts e.backtrace.inspect
      exit PD_ERROR_GET_SCHEDULE_BY_ID
    end

    def get_user_by_id(id)
      endpoint = "https://#{@subdomain}.pagerduty.com/api/v1/users/#{id}/?include[]=contact_methods"

      http_get_json(endpoint)

    rescue => e
      puts e.message
      puts e.backtrace.inspect
      exit PD_ERROR_GET_USER_BY_ID
    end

    def get_mobile_phone(user)
      phone = ""
      user["user"]["contact_methods"].each do |contact_method|
        phone = contact_method["phone_number"] if (contact_method["type"]  == "phone"  && 
                                                   contact_method["label"] == "Mobile" && 
                                                   phone.empty?)
      end

      raise "Unable to find mobile phone number." if phone.empty?
      phone

    rescue => e
      puts e.message
      puts e.backtrace.inspect
      exit PD_ERROR_GET_MOBILE_PHONE
    end

    private
    def http_get_json(endpoint)
      response = HTTParty.get(
        endpoint,
        headers: {
          'Content-Type'  => 'application/json', 
          'Authorization' => @token_string
        }
      )

      raise response.body unless response.code == 200
      JSON.parse(response.body)
    end
  end
 
  class Twilio

    # Error codes
    TWILIO_ERROR_VALIDATE_NUMBER = 2
    
    def initialize(account_sid, auth_token)
      @account_sid = account_sid
      @auth_token  = auth_token
      @client      = ::Twilio::REST::Client.new(@account_sid, @auth_token)
    end

    def get_forward_number(number_sid)
      voice_url_regex = /http:\/\/twimlets\.com\/forward\?PhoneNumber=(\d+)&/
      voice_url       = get_number(number_sid).voice_url 
      voice_url.match(voice_url_regex)[1]
    end

    def set_forward_number(number_sid, number_on_call)
      validate_number(number_on_call)
      url = forwarding_url(number_on_call)
      number = get_number(number_sid)
      number.update(:voice_url => url)
    end

    private
    def get_number(number_sid)
      @client.account.incoming_phone_numbers.get(number_sid)
    end

    def forwarding_url(number_on_call)
      # Forwarding twimlet does not handle sending extensions.
      number = number_on_call.split(",").first
      "http://twimlets.com/forward?PhoneNumber=#{number}&"
    end

    def validate_number(number)
      number = number.split(",")
      raise "Number: #{number} is invalid." unless number.first.length == 10
    rescue => e
      puts e.message
      puts e.backtrace.inspect
      exit TWILIO_ERROR_VALIDATE_NUMBER
    end
  end
end
