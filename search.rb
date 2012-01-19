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

    # 検索ワードは32語に制限されているので適当に短く
    text = tweet[0, 45]

    urls = Array.new

    https.start do |connection|
      # @todo 発言内容がRT, QTを含まないなら、-RT -QTするといい
      query = "#{text} twitter.com/#{author} site:twitter.com"
      # puts query
      urls += search(connection, query)

      query = "#{text} #{author} site:favstar.fm"
      # puts query
      urls += search(connection, query)
    end

    # ツイートIDを抽出
    # authorが一致しないものは弾く。不明なものはとりあえず残す
    ids = Array.new

    urls.each do |url|
      if url.match(%r|twitter.com/(\w+)/status(es)?/(\d+)|)
        user = $1
        id = $3
        # puts user, id

        if user == author
          ids << id
        end
      end

      if url.match(%r|favstar.fm/users/(\w+)/status/(\d+)|)
        user = $1
        id = $2
        # puts user, id

        if user == author
          ids << id
        end
      end

      if url.match(%r|favstar.fm/t/(\d+)|)
        id = $1
        ids << id
      end
    end

    ids
  end

  def search(connection, query)
    headers = {
      'Referer' => 'http://nickle.ath.cx/',
      'User-Agent' => 'mozillia'
    }

    path = "/ajax/services/search/web?v=1.0&q=#{URI.encode(query)}"

    response = connection.request_get(path, headers)

    data = JSON.parse(response.body)
    # puts JSON.pretty_generate(data)
    
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
