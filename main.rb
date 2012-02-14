#!ruby -Ku

require 'pp'
require 'twitter'
require 'yaml'

require './search'
require './tweet'
require './custom_bot'
require './watch'

$stdout.sync = true

config = YAML.load_file("config.yaml")

watcher = Watch.new(config['stream_account'])

config['bots'].each do |name, setting|
  watcher.add_bot(eval(setting['type']).new(setting))
end

loop do
  begin
    watcher.start()
  rescue => e
    # 不明なエラーのときも、とりあえず動き続ける
    puts "#{e} (#{e.class})"
    puts e.backtrace
  end

  # @todo logスリープ
  sleep 10
end
