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
