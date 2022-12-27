class TransactionsController < ApplicationController
  def index
    render json: user.point_transactions.order(:ts),
      only: %i[user_id payer_id points ts]
  end

  def create
    reward_points =
      RewardPoints.new(user: user, payer_name: payer_name, timestamp: timestamp, points: points)

    if reward_points.save
      render json: reward_points.point_transaction
    else
      render json: { errors: reward_points.errors }, status: :unprocessable_entity
    end
  end

  private

  def user_id
    params.require(:user_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  def transaction_params
    params.permit(:user_id, :payer, :points, :timestamp)
  end

  def payer_name
    transaction_params[:payer]
  end

  def points
    transaction_params[:points]&.to_i
  end

  def timestamp
    transaction_params[:timestamp]
  end
end
