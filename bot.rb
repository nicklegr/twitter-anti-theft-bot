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

  # @return ����������[text, author]�B���s������nil
  def parse_tweet(tweet)
    if tweet.match(/(.+) (\w+)$/)
      [$1, $2]
    else
      nil
    end
  end

  # �����c�C�[�g��2�x���c�C�[�g����ƁA
  # Twitter::Error::Forbidden(sharing is not permissable for this status (Share validations failed)) �����
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
      # �����炭����RT�ς�

      # RT��ID��T��
      page = 1
      old_retweet_id = nil
      
      loop do
        retweets = Twitter.retweeted_by(:count => 200, :page => page)
        break if retweets.nil? || retweets.empty?

        old_retweet = retweets.find do |status|
          status.retweeted_status.id == id
        end

        if old_retweet
          old_retweet_id = old_retweet.id
          break
        end

        page += 1
      end
      
      if old_retweet_id
        puts "removing old retweet (id #{old_retweet_id})"

        # ��U�폜
        Twitter.status_destroy(old_retweet_id)

        # ������҂�
        sleep(5)

        # �ēxRT
        Twitter.retweet(id)
      else
        puts "retweet failed: #{id}"
      end
    end
  end

  attr_reader :target, :target_id
end
