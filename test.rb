#!ruby -Ku

require 'twitter'
require 'yaml'
require 'pp'

require './search'
require './tweet'
require './bot'

config = YAML.load_file("config.yaml")

bot = Bot.new(config['bots'].first)

Twitter.user_timeline(bot.target).each do |status|
  # ––”ö‚Ìƒ†[ƒU–¼‚ğ•ª—£‚·‚é
  ret = bot.parse_tweet(status.text)
  return if !ret
  text, original_user = ret

  ids = Search.new.find_ids(text, original_user)
  if ids.size == 0
    puts "search not found: #{text} #{original_user}"
    return
  end

  original_id = Tweet.new.estimate_original(text, ids)
  if !original_id
    puts "no original found: #{text} #{original_user}"
    return
  end

  puts "#{original_id}: #{text} #{original_user}"
end
