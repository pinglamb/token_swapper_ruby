# frozen_string_literal: true

class Pool
  include Singleton
  include Redis::Objects

  list :asset_ids

  def id
    1
  end

  def assets
    asset_ids.collect { |aid| Asset.find(aid) }
  end

  def initialize
    asset_ids << Asset.create('WETH').id unless asset_ids.include?('WETH')
    asset_ids << Asset.create('USDC').id unless asset_ids.include?('USDC')
    asset_ids << Asset.create('USDT').id unless asset_ids.include?('USDT')
  end
end
