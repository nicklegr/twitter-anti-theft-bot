#!ruby -Ku

class Tweet
  # 発言のマッチングルール
  # 1. botの発言が、元発言に完全に含まれている
  # 2. 一致率が高い(発言長の差が少ない)
  def estimate_original(tweet, ids)
    ids.each do |id|
      status = Twitter.status(id)
      # pp status

      puts status.text
      puts status.created_at
      
      # status.retweet_count も参考になるかも。一桁は除外するとか
    end
  end
end
