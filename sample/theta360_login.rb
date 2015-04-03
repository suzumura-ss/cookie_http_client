require 'nokogiri'
require 'cookie_http_client'


client = CookieHTTPClient.new("https://theta360.com/authentication")
puts "#{client.uri.host}/#{client.uri.path}"
res = client.get{|uri|
  puts "=> #{uri.host}#{uri.path}"
  uri
}
select_html = Nokogiri::HTML(res.body)
path = select_html.xpath("//div[@class=\"login_fb\"]/a").attribute("data-href").value


client = CookieHTTPClient.new("https://theta360.com#{path}")
res = client.get{|uri|
  puts "=> #{uri.host}#{uri.path}"
  uri
}
login_dialog = Nokogiri::HTML(res.body)
form = login_dialog.xpath("//form[@id=\"login_form\"]")
params = form.xpath("//input").inject({}){|s,v|
  d = v.attribute('value')
  s[v.attribute('name').value] = d ? d.value: nil
  s
}
params['email'] = "valid-user@example.com"
params['pass'] = "password"

submit_u = client.last_uri.clone
action_u = URI.parse(form.attribute('action').value)
submit_u.path = action_u.path
submit_u.query = action_u.query


client = CookieHTTPClient.new(submit_u)
result = client.post_form(params){|uri|
  puts "=> #{uri.host}#{uri.path}"
  uri
}
