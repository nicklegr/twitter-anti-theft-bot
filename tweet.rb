#!ruby -Ku

class Tweet
  def estimate_original(tweet, ids)
    statuses = ids.map do |id|
      begin
        Twitter.status(id)
      rescue Twitter::Error::NotFound
        # puts "tweet #{id} deleted"
        nil
      end
    end

    statuses.compact!

    # pp tweet

    # statuses.each do |e|
    #   puts e.id
    #   puts e.text
    #   puts e.created_at
    #   puts ""
    # end

    statuses.select! do |e|
      # �����̃}�b�`���O���[��
      # 1. bot�̔������A�擪��v�Ō������Ɋ��S�Ɋ܂܂�Ă���
      return false if !e.text.match(/^#{tweet}/)

      # 2. ��v��������(�������̍������Ȃ�)
      #
      # 140�����W���X�g�̃c�C�[�g�ŁA��������ăA�J�E���g������ꂽ�Ƃ���
      # 140 * 0.8 = 112 -> �A�J�E���g�� 27�����ȓ�
      # 140 * 0.9 = 126 -> �A�J�E���g�� 13�����ȓ�
      rate = tweet.size.to_f / e.text.size
      return false if rate < 0.8

      true

      # status.retweet_count ���Q�l�ɂȂ邩���B�ꌅ�͏��O����Ƃ�
    end

    if statuses.size > 0
      original = statuses.min_by do |e| e.created_at end
      original.id
    else
      nil
    end
  end
end
