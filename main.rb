#!ruby -Ku

require 'pp'
require 'twitter'
require 'yaml'

require './search'
require './tweet'
require './bot'
require './watch'

config = YAML.load_file("config.yaml")

watcher = Watch.new(config['stream_account'])

config['bots'].each do |bot|
  watcher.add_bot(Bot.new(bot))
end

watcher.start()

# ☆1000ふぁぼツイート★は、ときどきアフィ発言が混ざる。ユーザー名が入っていないものは除外
