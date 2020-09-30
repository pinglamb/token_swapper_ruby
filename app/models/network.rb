# frozen_string_literal: true

class Network
  include Singleton
  include Redis::Objects

  list :account_ids
  list :token_ids

  def id
    1
  end

  def initialize
    unless token_ids.include?('WETH')
      token_ids << Token.create(name: 'Wrapped ETH', sym: 'WETH').id
    end
    unless token_ids.include?('USDC')
      token_ids << Token.create(name: 'USD Coin', sym: 'USDC').id
    end
    unless token_ids.include?('USDT')
      token_ids << Token.create(name: 'Tether USD', sym: 'USDT').id
    end
  end

  def tokens
    token_ids.collect do |tid|
      Token.find(tid)
    end
  end
end
