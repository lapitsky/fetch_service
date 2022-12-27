require 'rails_helper'

RSpec.describe PointTransaction do
  describe 'validations' do
    subject { build(:point_transaction) }

    it 'validates presence of payer' do
      expect(subject).to belong_to(:payer).required
    end

    it 'validates presence of user' do
      expect(subject).to belong_to(:user).required
    end

    it 'validates presence of points' do
      expect(subject).to validate_presence_of(:points)
    end

    it 'validates presence of timestamp' do
      expect(subject).to validate_presence_of(:ts)
    end

    it 'validates presence of adjusted_points' do
      expect(subject).to validate_presence_of(:adjusted_points)
    end

    it 'validates numericality of points' do
      expect(subject).to validate_numericality_of(:points).only_integer.is_other_than(0)
    end

    it 'validates numericality of adjusted points' do
      expect(subject).to validate_numericality_of(:adjusted_points).
        only_integer.is_greater_than_or_equal_to(0)
    end
  end

  describe '.unused' do
    subject { described_class.unused }

    it 'returns transactions with is_used set and does not include others' do
      used = create(:point_transaction, is_used: true)
      not_used = create(:point_transaction, is_used: false)

      expect(subject).to eq([not_used])
    end
  end

  describe '.balances' do
    subject { described_class.balances }

    it 'returns balances for every payer' do
      payer1 = create(:payer, name: 'P1')
      payer2 = create(:payer, name: 'P2')

      create(:point_transaction, payer: payer1, points: 100)
      create(:point_transaction, payer: payer1, points: -100)
      create(:point_transaction, payer: payer2, points: 200)
      create(:point_transaction, payer: payer2, points: -100)

      expect(subject).to eq('P1' => 0, 'P2' => 100)
    end
  end
end
