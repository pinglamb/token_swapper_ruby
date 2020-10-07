# frozen_string_literal: true

class Asset
  class NotInWhitelist < StandardError; end
  class NotEnoughCash < StandardError; end
  class NotEnoughLiabilities < StandardError; end

  include Redis::Objects

  attr_accessor :id

  value :address_value

  value :token_id
  value :lp_token_id

  value :cash_value
  value :liabilities_value
  value :dividend_value

  def address
    address_value.value
  end

  def token
    Token.find(token_id.value)
  end

  def lp_token
    Token.find(lp_token_id.value)
  end

  def sym
    token_id.value
  end

  def cash
    cash_value.value.to_d
  end

  def liabilities
    liabilities_value.value.to_d
  end

  def dividend
    dividend_value.value.to_d
  end

  def cov
    if liabilities.zero?
      0.0
    else
      cash / liabilities
    end
  end

  def deposit(from, amount)
    token.transfer(from, address, amount)
    # TODO: Proper LP minting with dividend handling
    lp_token.mint(from, amount)

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

  def add_dividend(amount)
    self.dividend_value = dividend + amount
  end

  def pp
    "#{sym}(cash: #{cash}, liabilities: #{liabilities}, dividend: #{dividend}, cov: #{cov})"
  end

  def self.create(token_id)
    raise NotInWhitelist unless token_id.in?(%w[WETH USDC USDT])

    if Pool.instance.asset_ids.include?(token_id)
      find(token_id)
    else
      new.tap do |a|
        a.id = token_id
        a.token_id = token_id
        a.address_value = "0x#{SecureRandom.hex(20)}"

        a.cash_value = 0
        a.liabilities_value = 0
        a.dividend_value = 0

        t = Token.find(token_id)
        lpt = Token.create(
          name: "#{t.name.value} (LP)",
          sym: "d#{t.sym.value}",
          initial_supply: 0
        )
        a.lp_token_id = lpt.id

        Pool.instance.asset_ids << a.id
      end
    end
  end

  def self.find(token_id)
    new.tap { |a| a.id = token_id }
  end
end
