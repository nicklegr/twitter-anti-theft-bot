#!ruby -Ku

require './search_engine'

class Search
  def find_ids(tweet, author, copy_user)
    ids = find_ids_in(GoogleAjaxSearch, tweet, author, copy_user)

    # 見つからない場合はカスタム検索でリトライ
    # こっちはQuotaが厳しいので、できるだけ使わないようにする
    if ids.size == 0
      ids = find_ids_in(GoogleCustomSearch, tweet, author, copy_user)
    end

    ids
  end

  def find_ids_in(engine, tweet, author, copy_user)
    ids = nil

    engine.new.start do |engine|
      # 検索ワードは32語に制限されているので適当に短く
      text = tweet[0, 45]
      ids = search(engine, text, author, copy_user)

      # 単語の途中で切れてしまうとヒットしないことがあるので、適当に長さを変えてリトライ
      # @todo ほんとは形態素解析
      if ids.size == 0
        text = tweet[0, 40]
        ids = search(engine, text, author, copy_user)
      end

      if ids.size == 0
        text = tweet[0, 35]
        ids = search(engine, text, author, copy_user)
      end
    end

    ids
  end

  def search(engine, text, author, copy_user)
    urls = Array.new

    # @todo 発言内容がRT, QTを含まないなら、-RT -QTするといい
    query = "#{text} site:twitter.com -#{copy_user}"
    query += " twitter.com/#{author}" if author

    # puts query
    urls += engine.query(query)

    query = "#{text} site:favstar.fm -#{copy_user}"
    query += " #{author}" if author

    # puts query
    urls += engine.query(query)

    # ツイートIDを抽出
    # authorが一致しないものは弾く。不明なものはとりあえず残す
    ids = Array.new

    urls.each do |url|
      if url.match(%r|twitter.com/(\w+)/status(es)?/(\d+)|)
        user = $1
        id = $3
        # puts user, id

        if user.downcase != copy_user.downcase
          if !author || user.downcase == author.downcase
            ids << id
          end
        end
      end

      if url.match(%r|favstar.fm/users/(\w+)/status/(\d+)|)
        user = $1
        id = $2
        # puts user, id

        if user.downcase != copy_user.downcase
          if !author || user.downcase == author.downcase
            ids << id
          end
        end
      end

      if url.match(%r|favstar.fm/t/(\d+)|)
        id = $1
        ids << id
      end
    end

    ids
  end
end
