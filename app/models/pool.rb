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
end
