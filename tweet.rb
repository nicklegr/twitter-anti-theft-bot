#!ruby -Ku

require 'uri'

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

class Tweet
  def estimate_original(tweet, author, ids)
    # API節約
    ids.sort!.uniq!

    statuses = ids.map do |id|
      begin
        Twitter.status(id)
      rescue Twitter::Error::NotFound
        # puts "tweet #{id} deleted"
        nil
      end
    end

    statuses.compact!
    statuses.delete_if do |e| e.user.screen_name != author end

    # pp tweet
    #
    # statuses.each do |e|
    #   puts e.id
    #   puts e.text
    #   puts e.user.screen_name
    #   puts e.created_at
    #   puts ""
    # end

    tweet = tweet.dup
    sanitize!(tweet)

    statuses.select! do |e|
      # 短縮URLはコピペポスト時に変更されるので、URLを除外
      original_text = e.text.gsub(URI.regexp, "")
      
      sanitize!(original_text)

      # pp tweet.unpack('U*'), original_text.unpack('U*')

      # 発言のマッチングルール
      # 1. botの発言が、先頭一致で元発言に完全に含まれている
      # 2. 一致率が高い(発言長の差が少ない)
      #
      # 140文字ジャストのツイートで、後ろを削ってアカウント名を入れたとして
      # 140 * 0.8 = 112 -> アカウント名 27文字以内
      # 140 * 0.9 = 126 -> アカウント名 13文字以内
      rate = tweet.size.to_f / original_text.size

      if original_text.starts_with?(tweet) && rate >= 0.8
        true
      else
        false
      end

      # status.retweet_count も参考になるかも。一桁は除外するとか
    end

    if statuses.size > 0
      original = statuses.min_by do |e| e.created_at end
      original.id
    else
      nil
    end
  end

  def sanitize!(str)
    # '～'は化けて'?'になったりするので、削除する
    str.gsub!(/\u003F|\u301C/, "")
  end
end
