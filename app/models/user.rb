class User < ApplicationRecord
  has_many :point_transactions

  validates_presence_of :name
  validates_uniqueness_of :name
end
