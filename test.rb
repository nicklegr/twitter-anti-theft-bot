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
# 原因不明。＼／ を削除してもだめ 160959001331376128 161623380125159425

# 対応済み。後でレグレッションテストを作る 160626812563619842 160641912154497024 161698877366484993

TWEET_IDS = %w!162484051633115136 162725643631591424 163103130773487617 163193727869911041 163223928389644288 163525916629286912 163541016178196480 163797707889192961!

config = YAML.load_file("config.yaml")

bot = Bot.new(config['bots'].first)

TWEET_IDS.each do |id|
  puts "tweet #{id} ----"

  status = Twitter.status(id)

  original_id = bot.find_original_id(status)
  next if !original_id

  puts "ok: #{original_id}"
end
