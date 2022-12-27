class PointTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :payer
  validates_presence_of :points, :adjusted_points, :ts
  validates :points, numericality: { only_integer: true, other_than: 0 }
  validates :adjusted_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :unused, -> { where(is_used: false) }

  def self.balances
    joins(:payer).select(:name, :points).group(:name).sum(:points)
  end
end
