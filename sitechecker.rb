############### Site Checker ###############
#  A simple Ruby script that checks a url for a 2xx status code. Follows redirects as well.
#  Change the settings as desired and invoke using "ruby site_checker.rb"
#
# Copyright 2009 Mike Larkin, Pixallent LLC
###########################################

require 'net/http'
require 'net/smtp'
require 'uri'


############### Settings ###############

SITES = %w{www.stealthpublisher.net}
FROM_EMAIL = "Pixellent Site Checker <no-reply@pixellent.com>"
TO_EMAIL =  "Pixellent Support <mikelarkin@pixellent.com>"
SMTP_SERVER = "localhost"
DEBUG = false

# true - will follow all redirects regardless of domain
# false	- will raise error if redirected
FOLLOW_REDIRECTS = true

# true - will allow a 503 (typical maintenance status code)
# false	- will raise error if exact address does not return 2xx
ALLOW_503 = true

############### Mail Helper ###############

def send_email(from, to, subject, message)
  msg = "From: #{from}\nTo: #{to}\nSubject: #{subject}\n#{message}"

  Net::SMTP.start(SMTP_SERVER) do |smtp|
    smtp.send_message msg, from, to
  end
end

############### File Helpers ###############

def send_up_alert(site, response)
  if File.exist?("status/#{site}")
    # Site was down, is now up
    puts "--#{site} was down, is now back up, sending email" if DEBUG
    File.delete("status/#{site}")
    send_email(FROM_EMAIL, TO_EMAIL, "#{site} is UP", "Status: #{response.code}\n\n #{response.body}")
  end
end

def send_down_alert(site, response)
  if !File.exist?("status/#{site}")
    puts "--Cannot reach #{site}, sending email" if DEBUG
    File.new("status/#{site}", "w")
    send_email(FROM_EMAIL, TO_EMAIL, "#{site} is DOWN", "Status: #{response.code}\n\n #{response.body}")
  end
end

############### Check Sites ###############

SITES.each do |site|
  url = URI.parse("http://#{site}")
  previous_location = nil
  begin
    found = false
    until found
      response = Net::HTTP.get_response(site, "/")
      previous_location = url
      response.header['location'] ? url = URI.parse("#{response.header['location']}") : found = true

      found = true if FOLLOW_REDIRECTS == false # Consider the initial request "found" if we're not following redirects
      found = true if previous_location == url # Check for infinite loop
    end

    # Make sure the code is in the 200 range
    if (response.code.to_i >= 200 && response.code.to_i < 300) || (response.code.to_i == 503 && ALLOW_503 == true)
		puts "-- #{site} is UP" if DEBUG
      send_up_alert(site, response)
    else
      # If not, email a notice if not already sent and write temp file
		puts "-- #{site} is DOWN" if DEBUG
		send_down_alert(site, response)
    end
  rescue => e
    # Invalid
    puts "-- #{site} is DOWN or script is broken: #{e.message}" if DEBUG
    send_down_alert(site, response)
  end

end
