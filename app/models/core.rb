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

      # TODO: Price Oracle
      price = 1

      ta.debit(amount * price)
      fa.credit(amount)

      # TODO: Transfer to account
      true
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
