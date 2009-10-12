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

SITES = %w{www.fetchapp.com www.synctobase.com www.pixallent.com}
FROM_EMAIL = "Pixallent Site Checker <no-reply@pixallent.com>"
TO_EMAIL =  "Pixallent Support <mikelarkin@pixallent.com>"
SMTP_SERVER = "localhost"

# true - will follow all redirects regardless of domain
# false	- will raise error if redirected
FOLLOW_REDIRECTS = false
                
# true - will allow a 503 (typical maintenance status code)
# false	- will raise error if exact address does not return 2xx
ALLOW_503 = true

############### Mail Helper ###############

def send_email(from, to, subject, message) 
	msg = <<END_OF_MESSAGE
From: #{from}
To: #{to}
Subject: #{subject}
	
#{message}
END_OF_MESSAGE
	              
  Net::SMTP.start(SMTP_SERVER) do |smtp|
    smtp.send_message msg, from, to
  end
end    

############### Check Sites ###############

SITES.each do |site|
  url = URI.parse("http://#{site}/")
  begin
  	 found = false
    until found
      host, port = url.host, url.port if url.host && url.port
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http|  http.request(req) }
		puts "XXXXXXXX #{url.host} | #{res.code}" 
      res.header['location'] ? url = URI.parse(res.header['location']) : found = true

		found = true if FOLLOW_REDIRECTS == false # Consider the initial request "found" if we're not following redirects
    end    
    # Make sure the code is in the 200 range
    unless (res.code.to_i >= 200 && res.code.to_i < 300) || (res.code.to_i == 503 && ALLOW_503 == true)
      # If not, email a notice
      puts "--Cannot reach #{site}, sending email--"
      send_email(FROM_EMAIL, TO_EMAIL, "#{site} is DOWN", "Status: #{res.code}\n\n #{res.body}")
    end
  rescue => e
    # Invalid
    puts "--Cannot reach #{site}, sending email--"
    send_email(FROM_EMAIL, TO_EMAIL, "#{site} is DOWN", "Message: #{e.message}")
  end

end