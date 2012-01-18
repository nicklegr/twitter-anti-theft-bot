#!ruby -Ku

require 'tweetstream'

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
    # followは、その人への in-reply-to や retweet も飛んでくる
    # 本人の発言以外を除外
    return if @bots.select {|e| e.target_id == status.user.id}.size == 0

    puts "#{status.user.id} #{status.user.screen_name} #{status.text}"
    pp status

    text = status.text
    user_id = status.user.id

    # 末尾のユーザ名を分離する
    # @todo ボットごとに処理を分けられるようにする
    return if !text.match(/(.+) (\w+)$/)
    text = $1
    original_user = $2

    # @todo 検索は時間がかかるので、非同期にするべき
    ids = Search.new.find_ids(text, original_user)
    if ids.size == 0
      puts "search not found: #{text} #{original_user}"
      return
    end

    original_id = Tweet.new.estimate_original(text, ids)
    if !original_id
      puts "no original found: #{text} #{original_user}"
      return
    end

    puts "retweet original: #{text}"
    bot = @bots.select{|e| e.target_id == user_id }.first
    bot.retweet(original_id)
  end
end
