FactoryBot.define do
  factory :point_transaction do
    user
    payer
    points { 100 }
    adjusted_points { 100 }
    is_used { false }
    ts { Time.current }
  end
end
