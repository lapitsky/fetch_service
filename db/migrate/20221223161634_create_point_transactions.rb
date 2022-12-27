class CreatePointTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :point_transactions do |t|
      t.references :user, foreign_key: true, null: false, index: true
      t.references :payer, foreign_key: true, null: false
      t.integer :points, null: false
      t.integer :adjusted_points, null: false
      t.datetime :ts, null: false
      t.boolean :is_used, null: false, default: false

      t.datetime :created_at, null: false

      t.index [:user, :payer], where: 'NOT is_used'
    end
  end
end
