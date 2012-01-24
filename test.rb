#!ruby -Ku

require 'twitter'
require 'yaml'
require 'pp'

require './search'
require './tweet'
require './bot'

# 非公式RT 159524563724681216 161004300682801152
# 鍵アカ。しかしsearch not foundは変 160672123780726784
# 削除済み 161744176076177408 161729076481110016
# ユーザーごと削除 161789475062693888
# ユーザー名が変わったケース。旧ユーザー名のURLでアクセスできる 161019399933923328
# 2回目のRT失敗 161653579399180289 128033080370937857

# 対応済み。後でレグレッションテストを作る 160626812563619842

TWEET_IDS = %w!160641912154497024 160959001331376128 161698877366484993!

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
