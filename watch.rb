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
      # follow�́A���̐l�ւ� in-reply-to �� retweet �����ł���
      # �{�l�̔����ȊO�����O
      bot = @bots.find {|e| e.target_id == status.user.id}
      return if !bot

      # puts "#{status.user.id} #{status.user.screen_name} #{status.text}"
      # pp status

      # �Z�kURL�̓R�s�y�|�X�g���ɕύX�����̂ŁAURL�����O
      text = status.text.gsub(URI.regexp, "")
      user_id = status.user.id

      # �����̃��[�U���𕪗�����
      ret = bot.parse_tweet(text)
      return if !ret
      text, original_user = ret

      # @todo �����͎��Ԃ�������̂ŁA�񓯊��ɂ���ׂ�
      ids = Search.new.find_ids(text, original_user)
      if ids.size == 0
        puts "#{bot.target}: search not found: #{status.id} #{original_user} #{text}"
        return
      end

      original_id = Tweet.new.estimate_original(text, original_user, ids)
      if !original_id
        puts "#{bot.target}: no original found: #{status.id} #{original_user} #{text}"
        return
      end

      bot.retweet(original_id)
      puts "#{bot.target}: ok: #{status.id} -> #{original_id}"
    rescue Twitter::Error::BadRequest => e
      # �悭����̂�Rate limit
      puts e.to_s
    rescue Twitter::Error::Forbidden => e
      # ���A�J�̏ꍇ����
      puts e.to_s
    rescue => e
      # �s���ȃG���[�̂Ƃ����A�Ƃ肠��������������
      puts e.to_s
    end
  end
end
