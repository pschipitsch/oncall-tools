require './OnCall'

twilio_account_sid = ""
twilio_auth_token  = ""
twilio_number_sid  = ""

pd_subdomain   = ""
pd_auth_token  = ""
pd_schedule_id = ""

pd_client     = OnCall::PagerDuty.new(pd_subdomain, pd_auth_token)
pd_schedule   = pd_client.get_schedule_by_id(pd_schedule_id)
pd_user_id    = pd_schedule["entries"].first["user"]["id"]
pd_user       = pd_client.get_user_by_id(pd_user_id)
pd_user_phone = pd_client.get_mobile_phone(pd_user)

twilio_client         = OnCall::Twilio.new(twilio_account_sid, twilio_auth_token)
twilio_forward_number = twilio_client.get_forward_number(twilio_number_sid)

twilio_client.set_forward_number(twilio_number_sid, pd_user_phone) unless twilio_forward_number == pd_user_phone
