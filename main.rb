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
