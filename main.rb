#!ruby -Ku

require 'pp'
require 'twitter'
require './search'
require './tweet'

# pp Twitter.search("ふぁぼれよ from:patatoma -RT -QT", :lang => "ja", :locale => "ja", :rpp => 100, :page => 1) # , 

tweet = "ふぁぼれよ"

ids = Search.new.find_ids(tweet, "patatoma")
# pp ids

Tweet.new.estimate_original(tweet, ids)

# ☆1000ふぁぼツイート★は、ときどきアフィ発言が混ざる。ユーザー名が入っていないものは除外
