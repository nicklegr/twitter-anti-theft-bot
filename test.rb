#!ruby -Ku

require 'twitter'
require 'yaml'
require 'pp'

require './search'
require './tweet'
require './bot'

# 非公式RT 159524563724681216
TWEET_IDS = %w!159449053569101824 159252759827324930!

config = YAML.load_file("config.yaml")

bot = Bot.new(config['bots'].first)

TWEET_IDS.each do |id|
  puts "tweet #{id} ----"

  status = Twitter.status(id)

  # 末尾のユーザ名を分離する
  ret = bot.parse_tweet(status.text)
  if !ret
    puts "parse_failed: #{status.text}"
    next
  end

  text, original_user = ret

  # 短縮URLはコピペポスト時に変更されるので、URLを除外
  text.gsub!(URI.regexp, "")

  ids = Search.new.find_ids(text, original_user)
  if ids.size == 0
    puts "search not found: #{text} #{original_user}"
    next
  end

  original_id = Tweet.new.estimate_original(text, original_user, ids)
  if !original_id
    puts "no original found: #{text} #{original_user}"
    next
  end

  puts "#{original_id}: #{text} #{original_user}"
end
