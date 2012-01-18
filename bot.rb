#!ruby -Ku

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

    Twitter.retweet(id)
  end

  attr_reader :target, :target_id
end
