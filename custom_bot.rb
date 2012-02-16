#!ruby -Ku

require './bot'

# ツイート末尾にアカウント名を入れてるタイプ
class BotAccountLast
  include Bot

  def parse_tweet(tweet)
    if tweet.match(/(.+) (\w+)$/)
      [$1, $2]
    else
      nil
    end
  end
end

# ツイート末尾にアカウント名を入れてるタイプ (スペースなし)
class BotAccountLastNoSpace
  include Bot

  def parse_tweet(tweet)
    if tweet.match(/(.+?)(\w+)$/)
      [$1, $2]
    else
      nil
    end
  end
end

# アカウント名を入れていないタイプ
class BotNoAccount
  include Bot

  def parse_tweet(tweet)
    [tweet, nil]
  end
end
