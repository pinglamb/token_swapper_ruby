# frozen_string_literal: true

class Oracle
  class << self
    def price(from, to)
      {
        %w[WETH USDC] => 353.90129,
        %w[USDC WETH] => 0.00283,
        %w[WETH USDT] => 354.51171,
        %w[USDT WETH] => 0.00282,
        %w[USDT USDC] => 0.99842,
        %w[USDC USDT] => 1.00158
      }[[from, to]].to_d
    end
  end
end
