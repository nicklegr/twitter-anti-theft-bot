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

# ツイッター名言bot特化
class BotTogetherMeigen
  include Bot

  def parse_tweet(tweet)
    msg = tweet.strip

    if msg.match(/(.+)[(（](.+?)[)）]$/)
      text = $1
      author = $2

      if author.match(/RT[:：](\w+)/)
        # "本文 (RT:user)" 形式
        author = $1
      end

      if author.match(/\w+/)
        # "本文 (user)" 形式
        return [text, author]
      else
        # "本文 (人名)" 形式
        # ツイートからの引用の場合があるので、本文のみで検索
        return [text, nil]
      end
    else
      return msg
    end
  end
end
