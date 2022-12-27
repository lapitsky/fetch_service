require 'rails_helper'

RSpec.describe TransactionsController do
  describe 'POST #create' do
    let(:user) { create(:user) }

    it 'creates points transaction' do
      payer = create(:payer)

      post :create, params: { user_id: user.id, points: 100, payer: payer.name, timestamp: '2022-10-31T10:00:00Z' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      transaction = PointTransaction.find(json['id'])
      expect(transaction.user_id).to eq(user.id)
      expect(transaction.payer_id).to eq(payer.id)
      expect(transaction.points).to eq(100)
      expect(transaction.ts).to eq(Time.parse('2022-10-31T10:00:00Z'))
    end

    it 'returns error response for non existing user' do
      post :create, params: { user_id: -1, points: 100 }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['errors']).to eq(['Entity is not found'])
    end

    it 'returns error response when points is not passed' do
      post :create, params: { user_id: user.id }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']['points']).to eq(['is not a number'])
    end
  end

  describe 'GET #index' do
    let(:user) { create(:user) }

    it 'returns transactions' do
      tx = create(:point_transaction, points: 100, user: user, ts: '2022-01-01T12:34:56Z')

      get :index, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
      expect(json[0]['user_id']).to eq(user.id)
      expect(json[0]['payer_id']).to eq(tx.payer_id)
      expect(json[0]['points']).to eq(100)
      expect(json[0]['ts']).to eq('2022-01-01T12:34:56.000Z')
    end

    it 'returns error response for non existing user' do
      get :index, params: { user_id: -1 }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['errors']).to eq(['Entity is not found'])
    end
  end
end
