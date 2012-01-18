#!ruby -Ku

class Tweet
  def estimate_original(tweet, ids)
    statuses = ids.map do |id|
      begin
        Twitter.status(id)
      rescue Twitter::Error::NotFound
        # puts "tweet #{id} deleted"
        nil
      end
    end

    statuses.compact!

    # pp tweet

    # statuses.each do |e|
    #   puts e.id
    #   puts e.text
    #   puts e.created_at
    #   puts ""
    # end

    statuses.select! do |e|
      # 発言のマッチングルール
      # 1. botの発言が、先頭一致で元発言に完全に含まれている
      return false if !e.text.match(/^#{tweet}/)

      # 2. 一致率が高い(発言長の差が少ない)
      #
      # 140文字ジャストのツイートで、後ろを削ってアカウント名を入れたとして
      # 140 * 0.8 = 112 -> アカウント名 27文字以内
      # 140 * 0.9 = 126 -> アカウント名 13文字以内
      rate = tweet.size.to_f / e.text.size
      return false if rate < 0.8

      true

      # status.retweet_count も参考になるかも。一桁は除外するとか
    end

    if statuses.size > 0
      original = statuses.min_by do |e| e.created_at end
      original.id
    else
      nil
    end
  end
end
