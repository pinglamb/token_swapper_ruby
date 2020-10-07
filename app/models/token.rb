# frozen_string_literal: true

class Token
  include Redis::Objects

  attr_accessor :id

  value :name
  value :sym
  value :address_value

  value :total_supply_value
  hash_key :balances_hash

  def address
    address_value.value
  end

  def total_supply
    total_supply_value.value.to_d
  end

  def balance_of(address)
    balances_hash[address].to_d || 0.to_d
  end

  def mint(address, amount)
    self.total_supply_value = total_supply + amount
    balances_hash[address] = amount
  end

  def transfer(from, to, amount)
    balances_hash[from] = balance_of(from) - amount
    balances_hash[to] = balance_of(to) + amount

    true
  end

  def self.create(name:, sym:, initial_supply: 0)
    if Network.instance.token_ids.include?(sym)
      find(sym)
    else
      new.tap do |t|
        t.id = sym
        t.name = name
        t.sym = sym
        t.address_value = "0x#{SecureRandom.hex(20)}"

        t.total_supply_value = 0

        t.mint(t.address, initial_supply)

        Network.instance.token_ids << t.id
      end
    end
  end

  def self.find(sym)
    Token.new.tap { |t| t.id = sym }
  end
end
