#!ruby -Ku

# Add a reader for retweeted_status (commit 617ebccb89)
module Twitter
  class Status
    # If this status is itself a retweet, the original tweet is available here.
    #
    # @return [Twitter::Status]
    def retweeted_status
      @retweeted_status ||= self.class.new(@attrs['retweeted_status']) unless @attrs['retweeted_status'].nil?
    end
  end
end

# 派生クラスで下記の定義が必要。
# 
# def parse_tweet(tweet)
#   @return 成功したら[text, author]。失敗したらnil
#   authorは、無記名のツイートの場合nilでもいい
#
module Bot
  def initialize(settings)
    @consumer_key = settings['consumer_key']
    @consumer_secret = settings['consumer_secret']
    @oauth_token = settings['oauth_token']
    @oauth_token_secret = settings['oauth_token_secret']

    Twitter.configure do |config|
      config.consumer_key = @consumer_key
      config.consumer_secret = @consumer_secret
      config.oauth_token = @oauth_token
      config.oauth_token_secret = @oauth_token_secret
    end

    @target = settings['target']
    @target_id = Twitter.user(@target).id
  end

  def find_original_id(status)
    # 短縮URLはコピペポスト時に変更されるので、URLを除外
    text = status.text.gsub(URI.regexp(['http', 'https']), "")

    # 末尾のユーザ名を分離する
    ret = parse_tweet(text)
    if !ret
      puts "#{@target}: parse failed: #{status.id} #{status.text}"
      return nil
    end

    text, original_user = ret
    copy_user = status.user.screen_name

    # @todo 検索は時間がかかるので、非同期にするべき
    ids = Search.new.find_ids(text, original_user, copy_user)
    if ids.size == 0
      warning "#{@target}: search not found: #{status.id} #{original_user} #{text}"
      return nil
    end

    original_id = Tweet.new.estimate_original(text, ids, copy_user)
    if !original_id
      warning "#{@target}: no original found: #{status.id} #{original_user} #{text}"
      return nil
    end
    
    original_id
  end

  # 同じツイートを2度リツイートすると、
  # Twitter::Error::Forbidden(sharing is not permissable for this status (Share validations failed)) が飛ぶ
  def retweet(id)
    Twitter.configure do |config|
      config.consumer_key = @consumer_key
      config.consumer_secret = @consumer_secret
      config.oauth_token = @oauth_token
      config.oauth_token_secret = @oauth_token_secret
    end

    begin
      Twitter.retweet(id)
    rescue Twitter::Error::Forbidden => e
      # おそらく既にRT済み

      # RTのIDを探す
      page = 1
      old_retweet_id = nil
      
      loop do
        retweets = Twitter.retweeted_by(:count => 200, :page => page)
        break if retweets.nil? || retweets.empty?

        old_retweet = retweets.find do |status|
          # RTしたツイートの元ツイートが削除されると、非公式RTに変わって
          # retweeted_statusがnilになる
          if status.retweeted_status
            status.retweeted_status.id == id
          else
            false
          end
        end

        if old_retweet
          old_retweet_id = old_retweet.id
          break
        end

        page += 1
      end
      
      if old_retweet_id
        puts "removing old retweet (id #{old_retweet_id})"

        # 一旦削除
        Twitter.status_destroy(old_retweet_id)

        # 完了を待つ
        sleep(5)

        # 再度RT
        Twitter.retweet(id)
      else
        warning "retweet failed: #{id}"
      end
    end
  end
  
  # ログに出力 + 管理者にDM送信
  def warning(str)
    puts str

    yaml = YAML.load_file("config.yaml")
    to = yaml['admin_account']

    Twitter.configure do |config|
      config.consumer_key = yaml['stream_account']['consumer_key']
      config.consumer_secret = yaml['stream_account']['consumer_secret']
      config.oauth_token = yaml['stream_account']['oauth_token']
      config.oauth_token_secret = yaml['stream_account']['oauth_token_secret']
    end

    str = str[0, 140]
    Twitter.direct_message_create(to, str)
  end

  attr_reader :target, :target_id
end
