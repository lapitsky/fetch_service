class SpendsController < ApplicationController
  def balances
    render json: PointTransaction.where(user: user).balances
  end

  def create
    spend_points =
      SpendPoints.new(user: user, timestamp: timestamp, points: points)

    if spend_points.save
      response = spend_points.point_transactions.
        map { |tx| { payer: tx.payer.name, points: tx.points } }
      render json: response
    else
      render json: { errors: spend_points.errors }, status: :unprocessable_entity
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
    params.permit(:user_id, :points, :timestamp)
  end

  def points
    transaction_params[:points]&.to_i
  end

  def timestamp
    transaction_params[:timestamp]
  end
end
