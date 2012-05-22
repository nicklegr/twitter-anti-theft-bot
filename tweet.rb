#!ruby -Ku

require 'uri'
require './blacklist'

# from http://d.hatena.ne.jp/kenkitii/20090204/ruby_levenshtein_distance
def levenshtein_distance(str1, str2)
  col, row = str1.size + 1, str2.size + 1
  d = row.times.inject([]){|a, i| a << [0] * col }
  col.times {|i| d[0][i] = i }
  row.times {|i| d[i][0] = i }

  str1.size.times do |i1|
    str2.size.times do |i2|
      cost = str1[i1] == str2[i2] ? 0 : 1
      x, y = i1 + 1, i2 + 1
      d[y][x] = [d[y][x-1]+1, d[y-1][x]+1, d[y-1][x-1]+cost].min
    end
  end
  d[str2.size][str1.size]
end

class Tweet
  def initialize
    @blacklist = BlackList.new

    yaml = YAML.load_file("config.yaml")

    Twitter.configure do |config|
      config.consumer_key = yaml['stream_account']['consumer_key']
      config.consumer_secret = yaml['stream_account']['consumer_secret']
      config.oauth_token = yaml['stream_account']['oauth_token']
      config.oauth_token_secret = yaml['stream_account']['oauth_token_secret']
    end
  end

  def estimate_original(tweet, ids, copy_user)
    # API節約
    ids.sort!.uniq!

    statuses = ids.map do |id|
      begin
        status = Twitter.status(id)
        status.retweeted_status || status
      rescue Twitter::Error::NotFound
        # puts "tweet #{id} deleted"
        nil
      rescue Twitter::Error::Forbidden
        # puts "tweet #{id} is from protected account"
        nil
      rescue => e
        # とりあえず落ちないように
        puts "tweet #{id}: #{e} (#{e.class})"
        puts e.backtrace
        nil
      end
    end

    statuses.compact!
    statuses.delete_if do |e| e.user.screen_name.downcase == copy_user.downcase end
    statuses.delete_if do |e| @blacklist.black_user?(e.user.screen_name.downcase) end

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

      # 発言のマッチングルール: 編集距離が、ツイート長と比較して少ない
      #
      # 140文字ジャストのツイートで、後ろを削ってアカウント名を入れたとして
      # 140 * 0.1 = 14 -> アカウント名 7文字以内
      # 140 * 0.2 = 28 -> アカウント名 14文字以内
      distance = levenshtein_distance(original_text, tweet)
      distance_rate = distance.to_f / original_text.size

      # pp distance
      # pp original_text.size

      if distance_rate <= 0.2
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

    # 改行コードなどもコピペ時に揺れがあるので削除
    str.gsub!(/\s+/, "")
    str.gsub!(/\u00A0+/, "") # NO-BREAK SPACE

    # ハッシュタグは#だけ削除しているらしい
    str.gsub!(/#/, "")
  end
end
