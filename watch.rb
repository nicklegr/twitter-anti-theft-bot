#!ruby -Ku

require 'tweetstream'
require 'uri'

require './search'
require './tweet'
require './bot'

class Watch
  def initialize(settings)
    TweetStream.configure do |config|
      config.consumer_key = settings['consumer_key']
      config.consumer_secret = settings['consumer_secret']
      config.oauth_token = settings['oauth_token']
      config.oauth_token_secret = settings['oauth_token_secret']
      config.auth_method = :oauth
    end

    @bots = Array.new
  end

  def add_bot(bot)
    @bots << bot
  end

  def start
    client = TweetStream::Client.new

    client.on_timeline_status do |status|
      on_new_status(status)
    end

    target_ids = @bots.map do |e| e.target_id end
    client.follow(target_ids)
  end

  def on_new_status(status)
    begin
      puts "#{status.user.id} #{status.user.screen_name} #{status.text}"
      # pp status

      # followは、その人への in-reply-to や retweet も飛んでくる
      # 本人の発言以外を除外
      bot = @bots.find {|e| e.target_id == status.user.id}
      return if !bot

      original_id = bot.find_original_id(status)

      if original_id
        bot.retweet(original_id)
        puts "#{bot.target}: ok: #{status.id} -> #{original_id}"
      end
    rescue Twitter::Error::BadRequest => e
      # よくあるのはRate limit
      puts e.to_s
    rescue Twitter::Error::Forbidden => e
      # 鍵アカの場合かな
      puts e.to_s
    rescue => e
      # 不明なエラーのときも、とりあえず動き続ける
      puts e.to_s
    end
  end
end
