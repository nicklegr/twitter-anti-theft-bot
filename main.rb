#!ruby -Ku

require 'pp'
require 'twitter'
require 'yaml'

require './search'
require './tweet'
require './bot'

# pp Twitter.search("ふぁぼれよ from:patatoma -RT -QT", :lang => "ja", :locale => "ja", :rpp => 100, :page => 1) # , 

tweet = "ふぁぼれよ"

ids = Search.new.find_ids(tweet, "patatoma")
# pp ids

original_id = Tweet.new.estimate_original(tweet, ids)
# pp original_id

bot_settings = YAML.load_file("bots.yaml")
Bot.new(bot_settings['bots'].first).retweet(original_id)

# ☆1000ふぁぼツイート★は、ときどきアフィ発言が混ざる。ユーザー名が入っていないものは除外
