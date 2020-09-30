# frozen_string_literal: true

class Token
  include Redis::Objects

  attr_accessor :id

  value :name
  value :sym

  def self.create(name:, sym:)
    Token.new.tap do |t|
      t.id = sym
      t.name = name
      t.sym = sym
    end
  end

  def self.find(sym)
    Token.new.tap { |t| t.id = sym }
  end
end
