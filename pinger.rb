require 'net/http'
require 'net/smtp'
require 'uri' 

SITES = %w{www.fetchapp.com www.synctobase.com www.pixallent.com www.stealthpublisher.com http://fetarp.com}
FROM_EMAIL = "Pixallent Pinger <no-reply@pixallent.com>"
TO_EMAIL =  "Pixallent Support <help@pixallent.com>"
SMTP_SERVER = "localhost"

def send_email(from, to, subject, message)
  msg = <<END_OF_MESSAGE
  From: #{from_alias} <#{from}>
  To: #{to_alias} <#{to}>
  Subject: #{subject}

  #{message}
END_OF_MESSAGE

  Net::SMTP.start(SMTP_SERVER_IP) do |smtp|
    smtp.send_message msg, from, to
  end
end

SITES.each do |site|
  url = URI.parse("http://#{site}/")
  begin

    found = false
    until found
      host, port = url.host, url.port if url.host && url.port
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http|  http.request(req) }
      res.header['location'] ? url = URI.parse(res.header['location']) : found = true
    end

    # Make sure the code is in the 200 range
    unless res.code.to_i >= 200 && res.code.to_i < 300
      # If not, email a notice
      puts "--Cannot reach #{site}, sending email--"
      send_email(FROM_EMAIL, TO_EMAIL, "#{site} is DOWN", "Status: #{res.code}\n\n #{res.body}")
    end
  rescue => e
    # Invalid
    puts "--Error checking #{site}--\n#{e.message}" 
  end

end
