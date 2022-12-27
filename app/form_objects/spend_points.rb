class SpendPoints
  include ActiveModel::Model

  attr_accessor :user, :payer, :points, :timestamp
  attr_reader :point_transactions

  validates_presence_of :user
  validates :points, numericality: { only_integer: true, greater_than: 0 }

  def initialize(attributes={})
    super
    @point_transactions = []
  end

  def save
    return false if invalid?

    success = false

    ActiveRecord::Base.transaction do
      spendings = populate_spendings
      success = !spendings.empty?
      raise ActiveRecord::Rollback unless success

      save_point_transactions(spendings)
    end

    success
  end

  private

  def populate_spendings
    spendings = {}
    scope = user.point_transactions.unused.includes(:payer).order(:ts)
    scope = scope.where(payer: payer) if payer
    total_spent = 0
    reward = scope.first
    @timestamp ||= Time.current

    while total_spent < points && reward do
      to_spend = [points - total_spent, reward.adjusted_points].min
      reward.update!(
        adjusted_points: reward.adjusted_points - to_spend,
        is_used: to_spend == reward.adjusted_points)

      spendings[reward.payer_id] ||= user.point_transactions.new(
        points: 0, adjusted_points: 0, payer: reward.payer, ts: timestamp, is_used: true)
      spendings[reward.payer_id].points -= to_spend

      reward = scope.reset.first
      total_spent += to_spend
    end

    return spendings if total_spent == points

    errors.add(:points, 'amount exceeds available points')
    return {}
  end

  def save_point_transactions(spendings)
    spendings.each do |(_, transaction)|
      transaction.save!
      @point_transactions << transaction
    end
  end
end
