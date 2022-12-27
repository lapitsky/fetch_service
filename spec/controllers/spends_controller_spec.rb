require 'rails_helper'

RSpec.describe SpendsController do
  describe 'POST #create' do
    let(:user) { create(:user) }

    it 'spends points and returns points breakdown' do
      payer1 = create(:payer)
      payer2 = create(:payer)
      create(:point_transaction, points: 100, adjusted_points: 50, user: user, payer: payer1, ts: '2022-01-01')
      create(:point_transaction, points: 200, adjusted_points: 150, user: user, payer: payer2, ts: '2022-01-02')

      post :create, params: { user_id: user.id, points: 100 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json[0]['payer']).to eq(payer1.name)
      expect(json[0]['points']).to eq(-50)
      expect(json[1]['payer']).to eq(payer2.name)
      expect(json[1]['points']).to eq(-50)
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

  describe 'GET #balances' do
    let(:user) { create(:user) }

    it 'returns points breakdown' do
      payer1 = create(:payer)
      payer2 = create(:payer)
      create(:point_transaction, points: 100, user: user, payer: payer1, ts: '2022-01-01')
      create(:point_transaction, points: 200, user: user, payer: payer2, ts: '2022-01-02')

      get :balances, params: { user_id: user.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json[payer1.name]).to eq(100)
      expect(json[payer2.name]).to eq(200)
    end

    it 'returns error response for non existing user' do
      get :balances, params: { user_id: -1 }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['errors']).to eq(['Entity is not found'])
    end
  end
end
