#!ruby -Ku

require 'uri'

class String
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end
end

class Tweet
  def estimate_original(tweet, author, ids)
    # API�ߖ�
    ids.sort!.uniq!

    statuses = ids.map do |id|
      begin
        Twitter.status(id)
      rescue Twitter::Error::NotFound
        # puts "tweet #{id} deleted"
        nil
      end
    end

    statuses.compact!
    statuses.delete_if do |e| e.user.screen_name != author end

    # pp tweet
    #
    # statuses.each do |e|
    #   puts e.id
    #   puts e.text
    #   puts e.user.screen_name
    #   puts e.created_at
    #   puts ""
    # end

    tweet = tweet.dup
    sanitize!(tweet)

    statuses.select! do |e|
      # �Z�kURL�̓R�s�y�|�X�g���ɕύX�����̂ŁAURL�����O
      original_text = e.text.gsub(URI.regexp, "")
      
      sanitize!(original_text)

      # pp tweet.unpack('U*'), original_text.unpack('U*')

      # �����̃}�b�`���O���[��
      # 1. bot�̔������A�擪��v�Ō������Ɋ��S�Ɋ܂܂�Ă���
      # 2. ��v��������(�������̍������Ȃ�)
      #
      # 140�����W���X�g�̃c�C�[�g�ŁA��������ăA�J�E���g������ꂽ�Ƃ���
      # 140 * 0.8 = 112 -> �A�J�E���g�� 27�����ȓ�
      # 140 * 0.9 = 126 -> �A�J�E���g�� 13�����ȓ�
      rate = tweet.size.to_f / original_text.size

      if original_text.starts_with?(tweet) && rate >= 0.8
        true
      else
        false
      end

      # status.retweet_count ���Q�l�ɂȂ邩���B�ꌅ�͏��O����Ƃ�
    end

    if statuses.size > 0
      original = statuses.min_by do |e| e.created_at end
      original.id
    else
      nil
    end
  end

  def sanitize!(str)
    # '�`'�͉�����'?'�ɂȂ����肷��̂ŁA�폜����
    str.gsub!(/\u003F|\u301C/, "")
  end
end
