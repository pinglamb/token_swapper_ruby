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
      message = "\n"

      fa = Asset.find(from)
      ta = Asset.find(to)

      message += "From: #{from}(cash: #{fa.cash}, liabilities: #{fa.liabilities})\n"
      message += "To: #{to}(cash: #{ta.cash}, liabilities: #{ta.liabilities})\n"
      message += "From Amount: #{amount}\n"

      price = Oracle.price(from, to)
      from_amount = amount
      to_amount = amount * price

      message += "==============================\n"
      message += "Oracle Price: #{price}\n"
      message += "To Amount: #{to_amount}\n"

      raise Asset::NotEnoughCash if ta.cash < to_amount

      from_before_cov = fa.cash / fa.liabilities
      to_before_cov = ta.cash / ta.liabilities
      from_after_cov = (fa.cash + from_amount) / fa.liabilities
      to_after_cov = (ta.cash - to_amount) / ta.liabilities

      message += "==============================\n"
      message += "From Cov (Before): #{from_before_cov}\n"
      message += "From Cov (After): #{from_after_cov}\n"
      message += "To Cov (Before): #{to_before_cov}\n"
      message += "To Cov (After): #{to_after_cov}\n"

      from_s = (s(from_after_cov) - s(from_before_cov)) / (from_after_cov - from_before_cov)
      to_s = (s(to_after_cov) - s(to_before_cov)) / (to_after_cov - to_before_cov)

      sft = to_s - from_s

      message += "Si: #{from_s}\n"
      message += "Sj: #{to_s}\n"
      message += "Sj - Si: #{sft}\n"

      adjusted_price = price * (1 + sft)
      adjusted_to_amount = amount * adjusted_price

      message += "==============================\n"
      message += "Adjusted Price: #{adjusted_price}\n"
      message += "Adjusted To Amount: #{adjusted_to_amount}\n"

      ta.debit(adjusted_to_amount)
      fa.credit(amount)

      # TODO: Transfer to account

      message
    end

    def s(x)
      a = 0.3
      b = 0.9

      if x >= 0 && a > x
        -x + (a + b) / 2
      elsif x >= a && b > x
        (x - b)**2 / 2 / (b - a)
      elsif x >= b
        0
      else # x < 0 ??
        0
      end
    end

    def pp
      message = "\n"

      message += "============== Assets ==============\n"
      Core.pool.assets.each do |asset|
        message += "#{asset.token_id.value}(cash: #{asset.cash}, liabilities: #{asset.liabilities}, coverage: #{asset.cov})"
        message += "\n"
      end

      message
    end
  end
end
