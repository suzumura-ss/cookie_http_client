require "cookie_http_client/version"
require 'uri'
require 'cgi'
require 'net/https'
require 'http/cookie'


class CookieHTTPClient
  THIS = CookieHTTPClient
  class HTTPFound < Exception
    attr_reader :redirect_uri, :source
    def initialize(httpFound, uri)
      @source = httpFound
      r = URI.parse(httpFound['location'])
      r.path = '/' if r.path.empty?
      r.scheme = uri.scheme unless r.scheme
      r.host   = uri.host   unless r.host
      @redirect_uri = URI.parse(r.to_s)
    end
  end

  class CookieJar < HTTP::CookieJar
    def cookie_string(uri)
      HTTP::Cookie.cookie_value(self.cookies(uri))
    end

    def set_cookie(str, uri)
      if str and !str.empty?
        self.parse(str, uri)
      end
    end
  end

  @@cookie_jar = nil
  def self.cookie_jar
    @@cookie_jar
  end
  def self.clear_cookie
    @@cookie_jar = CookieJar.new unless @@cookie_jar
    @@cookie_jar.clear
  end

protected
  def request(uri, header={})
    raise StandardError, "block required." unless block_given?
    path = [uri.path, uri.query].compact.join('?')
    http = @proxy.new(uri.host, uri.port)
    http.use_ssl = uri.scheme=='https'
    c = @@cookie_jar.cookie_string(uri)
    h = header.clone
    h["Cookie"] = c unless c.empty?
    r = yield(http, path, h)
    @@cookie_jar.set_cookie(r['set-cookie'], uri)
    raise HTTPFound.new(r, uri) if r.is_a? Net::HTTPFound or r.is_a? Net::HTTPMovedPermanently
    r
  end


public
  attr_reader :uri, :last_uri
  attr_accessor :max_redirect_count

  def initialize(uri, proxy=Net::HTTP)
    @@cookie_jar = CookieJar.new unless @@cookie_jar
    if uri.respond_to?(:path)
      @uri = uri
    else
      @uri = URI.parse(uri)
    end
    @uri.path = '/' if @uri.path.empty?
    @last_uri = nil
    @proxy = proxy
    @max_redirect_count = 10
  end

  # @param  header:Hash   request headers
  # @param  block         callback when redirect with `uri`
  # @return Net::HTTPResponse
  def get(header={})
    @last_uri = @uri.clone
    count = @max_redirect_count
    begin
      request(@last_uri, header){|http, path, header2|
        http.get(path, header2)
      }
    rescue HTTPFound =>e
      count-=1
      raise e if count==0
      @last_uri = e.redirect_uri
      @last_uri = yield(@last_uri) if block_given?
      retry
    end
  end

  # @param  data          post data
  # @param  header:Hash   request headers
  # @param  block         callback when redirect with `uri`
  # @return Net::HTTPResponse
  def post(data, header={}, &block)
    begin
      @last_uri = @uri
      request(@uri, header){|http, path, header2|
        http.post(path, data, header2)
      }
    rescue HTTPFound =>e
      @last_uri = e.redirect_uri
      @last_uri = yield(@last_uri) if block_given?
      n = THIS.new(@last_uri)
      r = n.get({}, &block)
      @last_uri = n.last_uri
      r
    end
  end

  # @param  params:Hash   post data
  # @param  header:Hash   request headers
  # @param  block         callback when redirect with `uri`
  # @return Net::HTTPResponse
  def post_form(params, header={}, &block)
    data = params.map{|k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"}.join('&')
    post(data, header, &block)
  end
end
