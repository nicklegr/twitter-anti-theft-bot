#!ruby -Ku

class Tweet
  # �����̃}�b�`���O���[��
  # 1. bot�̔������A�������Ɋ��S�Ɋ܂܂�Ă���
  # 2. ��v��������(�������̍������Ȃ�)
  def estimate_original(tweet, ids)
    ids.each do |id|
      status = Twitter.status(id)
      # pp status

      puts status.text
      puts status.created_at
      
      # status.retweet_count ���Q�l�ɂȂ邩���B�ꌅ�͏��O����Ƃ�
    end
  end
end
