#!ruby -Ku

require 'net/https'
require 'cgi'
require 'uri'
require 'json'

class Search
  def find_ids(tweet, author)
    https = Net::HTTP.new('ajax.googleapis.com',443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    https.verify_depth = 5

    # GET https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=Paris%20Hilton&key=INSERT-YOUR-KEY'  '

    # @todo 発言内容がRT, QTを含まないなら、-RT -QTするといい
    query = URI.encode("#{tweet} twitter.com/#{author} site:twitter.com")

    path = "/ajax/services/search/web?v=1.0&q=#{query}"

    headers = {
      # 'Referer' => 'http://nickle.ath.cx/',
      'User-Agent' => 'mozillia'
    }

    ids = Array.new

    https.start do |w|
      response = w.request_get(path, headers)

      data = JSON.parse(response.body)
      # puts JSON.pretty_generate(data)

      data['responseData']['results'].each do |entry|
        url = entry['url']
        # puts url

        if url.match(%r|twitter.com/(\w+)/status(es)?/(\d+)|)
          user = $1
          id = $3
          # puts user
          # puts id

          if user == author
            ids << id
          end
        end
      end
    end

    ids
  end
end
