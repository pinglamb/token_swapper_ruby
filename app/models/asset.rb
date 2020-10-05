# frozen_string_literal: true

class Asset
  class NotEnoughCash < StandardError; end
  class NotEnoughLiabilities < StandardError; end

  include Redis::Objects

  attr_accessor :id

  value :token_id

  value :cash_value
  value :liabilities_value
  value :dividend_value

  def token
    Token.find(token_id)
  end

  def sym
    token_id.value
  end

  def cash
    cash_value.value.to_f
  end

  def liabilities
    liabilities_value.value.to_f
  end

  def dividend
    dividend_value.value.to_f
  end

  def cov
    if liabilities.zero?
      0.0
    else
      cash / liabilities
    end
  end

  def deposit(amount)
    # TODO: Mint LP Token

    self.cash_value = cash + amount
    self.liabilities_value = liabilities + amount

    self
  end

  def withdraw(amount)
    # TODO: Burn LP Token
    # TODO: Dividend

    raise NotEnoughCash if cash < amount
    raise NotEnoughLiabilities if liabilities < amount

    self.cash_value = cash - amount
    self.liabilities_value = liabilities - amount

    self
  end

  def credit(amount)
    self.cash_value = cash + amount
  end

  def debit(amount)
    raise NotEnoughCash if cash < amount

    self.cash_value = cash - amount
  end

  def fee(amount)
    self.dividend_value = dividend + amount
  end

  def pp
    "#{sym}(cash: #{cash}, liabilities: #{liabilities}, dividend: #{dividend}, cov: #{cov})"
  end

  def self.create(token_id)
    new.tap do |a|
      a.id = token_id
      a.token_id = token_id
      a.cash_value = 0
      a.liabilities_value = 0
      a.dividend_value = 0
    end
  end

  def self.find(token_id)
    new.tap { |a| a.id = token_id }
  end
end
