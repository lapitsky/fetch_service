require 'rails_helper'

RSpec.describe RewardPoints do
  describe '#save' do
    subject { described_class.new(attributes) }

    let(:payer) { create(:payer) }
    let(:payer_name) { payer.name }
    let(:user) { create(:user) }
    let(:points) { 100 }
    let(:ts) { '2022-12-12' }
    let(:attributes) { { user: user, payer_name: payer_name, points: points, timestamp: ts } }

    describe 'when user or timestamp are not provided' do
      let(:user) { nil }
      let(:ts) { nil }

      it 'validates presence of user and timestamp' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(2)
        expect(subject.errors[:user]).to eq(["can't be blank"])
        expect(subject.errors[:timestamp]).to eq(["can't be blank"])
      end
    end

    describe 'when points is zero' do
      let(:points) { 0 }

      it 'disables saving of zero points' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(1)
        expect(subject.errors[:points]).to eq(['must be other than 0'])
      end
    end

    describe 'when payer with the given name does not exist' do
      let(:payer_name) { 'Dummy payer' }

      it 'disables saving with incorrect payer name' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(1)
        expect(subject.errors[:payer_name]).to eq(['should exist'])
      end
    end

    describe 'when points is a positive number' do
      it 'creates point transaction with positive points' do
        expect(subject.save).to eq(true)
        expect(subject.point_transaction).not_to be_nil
        expect(subject.point_transaction).to be_persisted
        expect(subject.point_transaction.user).to eq(user)
        expect(subject.point_transaction.payer).to eq(payer)
        expect(subject.point_transaction.points).to eq(points)
        expect(subject.point_transaction.is_used).to eq(false)
        expect(subject.point_transaction.ts).to eq(ts)
      end
    end

    describe 'when points is a negative number' do
      let(:points) { -200 }

      it 'checks for insufficient points' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(1)
        expect(subject.errors['points']).to eq(['amount exceeds available points'])
      end

      it 'creates a transaction with negative amount and deduces points from other transactions of the payer' do
        create(:point_transaction, ts: '2022-12-01')
        transaction = create(
          :point_transaction, points: 250, adjusted_points: 250, payer: payer, user: user, ts: '2022-12-02')

        expect(subject.save).to eq(true)
        expect(transaction.reload.adjusted_points).to eq(50)
        expect(subject.point_transaction).not_to be_nil
        expect(subject.point_transaction).to be_persisted
        expect(subject.point_transaction.user).to eq(user)
        expect(subject.point_transaction.payer).to eq(payer)
        expect(subject.point_transaction.points).to eq(points)
        expect(subject.point_transaction.adjusted_points).to be_zero
        expect(subject.point_transaction.is_used).to eq(true)
        expect(subject.point_transaction.ts).to eq(ts)
      end
    end
  end
end
