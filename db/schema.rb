# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_12_23_161634) do
  create_table "payers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_payers_on_name", unique: true
  end

  create_table "point_transactions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "payer_id", null: false
    t.integer "points", null: false
    t.integer "adjusted_points", null: false
    t.datetime "ts", null: false
    t.boolean "is_used", default: false, null: false
    t.datetime "created_at", null: false
    t.index "\"user\", \"payer\"", name: "index_point_transactions_on_user_and_payer", where: "NOT is_used"
    t.index ["payer_id"], name: "index_point_transactions_on_payer_id"
    t.index ["user_id"], name: "index_point_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "point_transactions", "payers"
  add_foreign_key "point_transactions", "users"
end
