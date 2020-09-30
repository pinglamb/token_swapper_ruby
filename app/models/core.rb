# frozen_string_literal: true

class Core
  class << self
    def network
      Network.instance
    end

    def pool
      Pool.instance
    end

    def reset
      Redis::Objects.redis.flushall
    end

    def swap(from, to, amount)
      fa = Asset.find(from)
      ta = Asset.find(to)

      price = Oracle.price(from, to)

      received = amount * price
      ta.debit(received)
      fa.credit(amount)

      # TODO: Transfer to account

      received
    end

    def slippage_curve(x)
      p1 = 3
      p2 = 200
      if x.zero?
        0.0
      else
        1 + 1 / (p2**(x**p1) - 1)
      end
    end

    def pp
      message = "\n"

      message += "============== Assets ==============\n"
      Core.pool.assets.each do |asset|
        message += "#{asset.token_id.value}(cash: #{asset.cash}, liabilities: #{asset.liabilities})"
        message += "\n"
      end

      message
    end
  end
end
