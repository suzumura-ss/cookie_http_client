require 'cookie_http_client'

describe CookieHTTPClient do
  before(:all) do
    @proxy =if ENV['HTTP_PROXY']
              uri = URI.parse(ENV['HTTP_PROXY'])
              Net::HTTP.Proxy(uri.host, uri.port, uri.user, uri.password)
            else
              Net::HTTP
            end
  end

  context "GET request" do
    before(:all) do
      @client = CookieHTTPClient.new("http://goo.gl/IwTffS", @proxy)
      @redirect = nil
      @res = @client.get{|uri|
        @redirect = uri
      }
    end

    it {
      expect(@res.code).to be == "200"
    }
    it {
      expect(@client.last_uri.to_s).to be == "https://github.com/suzumura-ss/cookie_http_client"
    }
    it {
      expect(@redirect).not_to be_nil
    }

    it {
      client = CookieHTTPClient.new("https://github.com/suzumura-ss/cookie_http_client", @proxy)
      res = client.get
      expect(CookieHTTPClient.cookie_jar.cookies(client.last_uri).size).to be > 0
      CookieHTTPClient.cookie_jar.clear
      expect(CookieHTTPClient.cookie_jar.cookies(client.last_uri).size).to be == 0
    }
  end

  context "POST request" do
    before(:all) do
      q = {'type'=>'DOM', 'key'=>'amazon.co.jp'}
      @client = CookieHTTPClient.new("http://whois.jprs.jp/", @proxy)
      @res = @client.post_form(q)
    end

    it {
      expect(@res.code).to be == "200"
    }
    it {
      expect(@res.body).to match(/AMAZON.CO.JP/)
    }
  end
end
