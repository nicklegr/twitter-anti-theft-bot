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

class Bot
  def initialize(settings)
    @target = settings['target']
    @target_id = settings['target_id']
    @consumer_key = settings['consumer_key']
    @consumer_secret = settings['consumer_secret']
    @oauth_token = settings['oauth_token']
    @oauth_token_secret = settings['oauth_token_secret']
  end

  # @return 成功したら[text, author]。失敗したらnil
  def parse_tweet(tweet)
    if tweet.match(/(.+) (\w+)$/)
      [$1, $2]
    else
      nil
    end
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
      retweet_status = Twitter.retweeted_by(:count => 200).find do |status| status.retweeted_status.id == id end
      # pp retweet_status.id

      # 一旦削除
      Twitter.status_destroy(retweet_status.id)

      # 完了を待つ
      sleep(5)

      # 再度RT
      Twitter.retweet(id)
    end
  end

  attr_reader :target, :target_id
end
