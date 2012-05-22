#!ruby -Ku

class BlackList
  def initialize
    config = YAML.load_file("config.yaml")
    @black_users = config['black_users'].map do |e| e.downcase end
  end

  def black_user?(user)
    @black_users.include?(user)
  end
end
