class RewardPoints
  include ActiveModel::Model

  attr_accessor :user, :payer_name, :points, :timestamp
  attr_reader :point_transaction

  validates_presence_of :user, :timestamp
  validates :points, numericality: { only_integer: true, other_than: 0 }
  validate :payer_should_exist

  def save
    return false if invalid?

    if points > 0
      @point_transaction = user.point_transactions.new(
        payer: payer, points: points, adjusted_points: points, ts: timestamp)
      return false unless save_object(@point_transaction)
    else
      spend_points = SpendPoints.new(
        user: user, payer: payer, points: -points, timestamp: timestamp)
      return false unless save_object(spend_points)

      @point_transaction = spend_points.point_transactions.first
    end

    true
  end

  private

  def payer_should_exist
    errors.add(:payer_name, 'should exist') if payer.nil?
  end

  def payer
    return @payer if defined? @payer
    @payer = Payer.find_by(name: payer_name)
  end

  def save_object(object)
    return true if object.save

    object.errors.each do |e|
      errors.add(e.attribute, e.message)
    end

    false
  end
end
