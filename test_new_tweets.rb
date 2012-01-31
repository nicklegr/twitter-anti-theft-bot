#!ruby -Ku

# 指定したbotの最新のツイートを検索するテスト

TEST_BOT_NAME = '100favs'

require 'twitter'
require 'yaml'
require 'pp'

require './search'
require './tweet'
require './bot'
require './custom_bot'

config = YAML.load_file("config.yaml")
setting = config['bots'][TEST_BOT_NAME]

bot = eval(setting['type']).new(setting)

Twitter.user_timeline(bot.target).each do |status|
  print "tweet #{status.id} => "

  original_id = bot.find_original_id(status)
  next if !original_id

  puts "ok: #{original_id}"
end
