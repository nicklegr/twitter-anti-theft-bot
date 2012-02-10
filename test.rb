#!ruby -Ku

# 指定したツイートIDを検索するテスト

require 'twitter'
require 'yaml'
require 'pp'

require './search'
require './tweet'
require './bot'
require './custom_bot'

# 非公式RT 159524563724681216 161004300682801152
# 鍵アカ。しかしsearch not foundは変 160672123780726784
# 削除済み 161744176076177408 161729076481110016 163797707889192961 164658378143051776
# ユーザーごと削除 161789475062693888
# ユーザー名が変わったケース。旧ユーザー名のURLでアクセスできる 164567781264736256
# 2回目のRT失敗 161653579399180289 128033080370937857
# 原因不明。＼／ を削除してもだめ 160959001331376128 161623380125159425
# 切り捨て位置が悪い 162484051633115136
# URLのドメイン部分がIPになってる 155876798524178433

# 対応済み。後でレグレッションテストを作る 160626812563619842 160641912154497024 161698877366484993 163103130773487617 161019399933923328 162725643631591424 163525916629286912 163193727869911041 163541016178196480 164567781264736256

# 名言botの方を拾った
# https://twitter.com/#!/100favs/status/155492861729705984 => https://twitter.com/#!/agitadashi/status/110322819149201408

# 微妙に表記が変えてある
# https://twitter.com/#!/100favs/status/155639929655934976 => https://twitter.com/#!/amneris84/status/104766160456794112

TEST_VECTOR = {
  '1000favs' => %w!166807114260561920 167078904719347712 167124203479371776 167471492060286977 167788582575157248 167833879179296770 167848979005046784!,
  '100favs' => %w!!
}

config = YAML.load_file("config.yaml")

TEST_VECTOR.each do |bot_name, tweet_ids|
  setting = config['bots'][bot_name]

  bot = eval(setting['type']).new(setting)

  tweet_ids.each do |id|
    print "tweet #{id} => "

    status = Twitter.status(id)

    original_id = bot.find_original_id(status)

    if original_id
      puts "ok: #{original_id}"
    end

    # GoogleのRate limit対策
    sleep 10
  end
end
