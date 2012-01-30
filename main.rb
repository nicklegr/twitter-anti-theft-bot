#!ruby -Ku

require 'pp'
require 'twitter'
require 'yaml'

require './search'
require './tweet'
require './custom_bot'
require './watch'

config = YAML.load_file("config.yaml")

watcher = Watch.new(config['stream_account'])

config['bots'].each do |name, setting|
  watcher.add_bot(eval(setting['type']).new(setting))
end

watcher.start()
