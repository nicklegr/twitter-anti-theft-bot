#!ruby -Ku

require 'net/https'
require 'cgi'
require 'uri'
require 'json'
require 'yaml'

module SearchEngine
  def initialize
    @https = Net::HTTP.new(domain(), 443)
    @https.use_ssl = true
    @https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @https.verify_depth = 5
  end

  def start
    @https.start do |https|
      yield self
    end
  end
end

class GoogleAjaxSearch
  include SearchEngine

  def domain
    'ajax.googleapis.com'
  end

  def query(phrase)
    headers = {
      'Referer' => 'http://nickle.ath.cx/',
      'User-Agent' => 'mozillia'
    }

    path = "/ajax/services/search/web?v=1.0&q=#{URI.encode(phrase)}&rsz=large&hl=ja&safe=off"
    response = @https.request_get(path, headers)

    data = JSON.parse(response.body)
    # puts JSON.pretty_generate(data)

    if data['responseStatus'] != 200
      msg = "search failed"
      msg += ": #{data['responseDetails']}" if data['responseDetails']
      puts msg

      return []
    end
    
    # @todo 例外？
    return [] if !data
    return [] if !data['responseData']
    return [] if !data['responseData']['results']

    urls = Array.new

    data['responseData']['results'].each do |entry|
      urls << entry['url']
    end

    urls
  end
end

class GoogleCustomSearch
  include SearchEngine

  def initialize
    super

    config = YAML.load_file("config.yaml")['google_api']
    @api_key = config['key']
    @cse_id = config['cse_id']
  end

  def domain
    'www.googleapis.com'
  end

  def query(phrase)
    path = "/customsearch/v1?key=#{@api_key}&cx=#{@cse_id}&q=#{URI.encode(phrase)}&hl=ja"
    response = @https.request_get(path)

    data = JSON.parse(response.body)
    # puts JSON.pretty_generate(data)

    # @todo ステータスコード, Rate limitチェック

    # @todo 例外？
    return [] if !data
    return [] if !data['items']

    data['items'].map do |entry| entry['link'] end
  end
end
