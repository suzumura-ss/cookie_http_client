# CookieHttpClient

HTTP clinet with cookie suppot.


## Installation

Add this line to your application's Gemfile:

    gem 'cookie_http_client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cookie_http_client

## Usage


### Basic GET/POST request

    client = CookieHTTPClient.new("http://goo.gl/IwTffS")
    res = client.get #=> Net::HTTPResponse
    client.last_uri  #=> https://github.com/suzumura-ss/cookie_http_client

    client = CookieHTTPClient.new("http://whois.jprs.jp/")
    params = {'type'=>'DOM', 'key'=>'amazon.co.jp'}
    res = client.post_form(params) #=> Net::HTTPResponse


### Hooking redirection

    client = CookieHTTPClient.new("http://goo.gl/IwTffS")
    res = client.get{|uri|
      # `uri` is URI of location-header.
      # You can modify uri.
      uri
    }
    

## Contributing

1. Fork it ( http://github.com/<my-github-username>/cookie_http_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
