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

      message += "From: #{fa.pp}\n"
      message += "To: #{ta.pp}\n"

      price = Oracle.price(from, to)
      from_amount = amount
      to_amount = amount * price

      message += "==============================\n"
      message += "Oracle Price: #{price}\n"
      message += "Ideal Δfrom:  #{from_amount}\n"
      message += "Ideal Δto:    #{to_amount}\n"

      from_before_cov = fa.cash / fa.liabilities
      to_before_cov = ta.cash / ta.liabilities
      from_after_cov = (fa.cash + from_amount) / fa.liabilities
      to_after_cov = (ta.cash - to_amount) / ta.liabilities

      message += "==============================\n"
      message += "from-r: #{from_before_cov}\n"
      message += "from-r': #{from_after_cov}\n"
      message += "to-r: #{to_before_cov}\n"
      message += "to-r': #{to_after_cov}\n"

      from_slippage = (s(from_after_cov) - s(from_before_cov)) / (from_after_cov - from_before_cov)
      to_slippage = (s(to_after_cov) - s(to_before_cov)) / (to_after_cov - to_before_cov)
      sft = to_slippage - from_slippage

      message += "from-f(r): #{s(from_before_cov)}\n"
      message += "from-f(r'): #{s(from_after_cov)}\n"
      message += "from-slippage: #{from_slippage * 100}%\n"
      message += "to-f(r): #{s(to_before_cov)}\n"
      message += "to-f(r'): #{s(to_after_cov)}\n"
      message += "to-slippage: #{to_slippage * 100}%\n"
      message += "swapping slippage: #{sft * 100}%\n"

      haircut_percent = '0.001'.to_d
      retention_percent = '0.2'.to_d
      haircut = to_amount * haircut_percent
      retention = haircut * retention_percent
      dividend = haircut - retention

      message += "==============================\n"
      message += "haircut %: #{haircut_percent * 100}\n"
      message += "haircut (#{ta.sym}): #{haircut}\n"
      message += "retention (#{ta.sym}): #{retention}\n"
      message += "dividend (#{ta.sym}): #{dividend}\n"

      adjusted_price = price * (1 + sft)
      adjusted_to_amount = amount * adjusted_price
      user_to_amount = adjusted_to_amount - haircut

      message += "==============================\n"
      message += "Actual Δfrom:  #{from_amount}\n"
      message += "Actual Δto:    #{user_to_amount}\n"

      ta.debit(adjusted_to_amount - retention)
      fa.credit(from_amount)
      ta.add_dividend(dividend)

      message += "======== After Swap ==========\n"
      message += "From: #{fa.pp}\n"
      message += "To: #{ta.pp}\n"

      # TODO: Transfer to account

      message
    end

    def s(x)
      a = 0.4
      b = 1.0

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
        message += asset.pp
        message += "\n"
      end

      message
    end
  end
end
