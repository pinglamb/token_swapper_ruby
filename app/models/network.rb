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

  def pp
    message = "\n"

    message += "============== Accounts ============\n"
    accounts.each do |a|
      message += a.pp
      message += "\n"
    end

    message += "============== Tokens ==============\n"
    tokens.each do |t|
      message += t.pp
      message += "\n"
    end

    message
  end
end
