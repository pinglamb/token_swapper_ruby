# frozen_string_literal: true

class Account
  include Redis::Objects

  attr_accessor :id

  value :name_value
  value :address_value

  def name
    name_value.value
  end

  def address
    address_value.value
  end

  def pp
    message = "#{name} ("
    message += Network.instance.token_ids.each_with_object({}) do |tid, h|
      h[tid] = Token.find(tid).balance_of(address)
    end.select { |_k, v| v > 0 }.collect { |k, v| "#{k}: #{v}" }.join(', ')

    message += ')'
  end

  def self.create(name)
    if Network.instance.account_ids.include?(name)
      find(name)
    else
      new.tap do |a|
        a.id = name
        a.name_value = name
        a.address_value = "0x#{SecureRandom.hex(20)}"

        Network.instance.account_ids << a.id
      end
    end
  end

  def self.find(id)
    new.tap { |a| a.id = id }
  end
end
