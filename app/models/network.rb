# frozen_string_literal: true

class Network
  include Singleton
  include Redis::Objects

  list :account_ids
  list :token_ids

  def id
    1
  end

  def accounts
    account_ids.collect do |aid|
      Account.find(aid)
    end
  end

  def tokens
    token_ids.collect do |tid|
      Token.find(tid)
    end
  end
end
