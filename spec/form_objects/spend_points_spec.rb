require 'rails_helper'

RSpec.describe SpendPoints do
  describe '#save' do
    subject { described_class.new(attributes) }

    let(:user) { create(:user) }
    let(:points) { 100 }
    let(:attributes) { { user: user, points: points } }

    describe 'when user is not provided' do
      let(:user) { nil }

      it 'validates presence of user and timestamp' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(1)
        expect(subject.errors[:user]).to eq(["can't be blank"])
      end
    end

    describe 'when points is negative' do
      let(:points) { -1 }

      it 'disables saving of zero points' do
        expect(subject.save).to eq(false)
        expect(subject.errors.count).to eq(1)
        expect(subject.errors[:points]).to eq(['must be greater than 0'])
      end
    end

    describe 'when enough of points exist' do
      it 'creates point transaction with positive points' do
        tx = create(:point_transaction, points: 100, adjusted_points: 100, user: user)
        payer = tx.payer

        expect(subject.save).to eq(true)
        expect(subject.point_transactions).not_to be_empty
        expect(subject.point_transactions).to all(be_persisted)
        expect(subject.point_transactions.count).to eq(1)

        new_transaction = subject.point_transactions.first
        expect(new_transaction.user).to eq(user)
        expect(new_transaction.payer).to eq(payer)
        expect(new_transaction.points).to eq(-points)
        expect(new_transaction.is_used).to eq(true)

        expect(tx.reload.adjusted_points).to be_zero
        expect(tx.reload.is_used).to eq(true)
      end

      describe 'when multiple point transactions from different payers exist' do
        let(:payer1) { create(:payer) }
        let(:payer2) { create(:payer) }
        let(:tx1) do
          create(:point_transaction, points: 100, adjusted_points: 50, user: user, payer: payer1, ts: '2022-01-01')
        end
        let(:tx2) do
          create(:point_transaction, points: 200, adjusted_points: 150, user: user, payer: payer2, ts: '2022-01-02')
        end
        let(:tx3) do
          create(:point_transaction, points: 50, adjusted_points: 50, user: user, payer: payer1, ts: '2022-01-03')
        end

        before do
          tx1
          tx2
          tx3
        end

        it 'splits spendings between many transactions of different payers if payer is not passed' do
          expect(subject.save).to eq(true)
          expect(subject.point_transactions).not_to be_empty
          expect(subject.point_transactions).to all(be_persisted)
          expect(subject.point_transactions.count).to eq(2)

          new_transaction1 = subject.point_transactions.first
          new_transaction2 = subject.point_transactions.second
          expect(new_transaction1.user).to eq(user)
          expect(new_transaction1.payer).to eq(payer1)
          expect(new_transaction1.points).to eq(-50)
          expect(new_transaction1.is_used).to eq(true)
          expect(new_transaction2.user).to eq(user)
          expect(new_transaction2.payer).to eq(payer2)
          expect(new_transaction2.points).to eq(-50)
          expect(new_transaction2.is_used).to eq(true)

          expect(tx1.reload.adjusted_points).to be_zero
          expect(tx1.reload.is_used).to eq(true)
          expect(tx2.reload.adjusted_points).to eq(100)
          expect(tx2.reload.is_used).to eq(false)
        end

        it 'splits spendings between transactions of the payer if payer is passed' do
          attributes.merge!(payer: payer1)
          expect(subject.save).to eq(true)
          expect(subject.point_transactions).not_to be_empty
          expect(subject.point_transactions).to all(be_persisted)
          expect(subject.point_transactions.count).to eq(1)

          new_transaction = subject.point_transactions.first
          expect(new_transaction.user).to eq(user)
          expect(new_transaction.payer).to eq(payer1)
          expect(new_transaction.points).to eq(-100)
          expect(new_transaction.is_used).to eq(true)

          expect(tx1.reload.adjusted_points).to be_zero
          expect(tx1.reload.is_used).to eq(true)
          expect(tx3.reload.adjusted_points).to be_zero
          expect(tx3.reload.is_used).to eq(true)
        end
      end
    end
  end
end
