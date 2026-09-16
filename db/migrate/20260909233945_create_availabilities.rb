class CreateAvailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :availabilities do |t|
      t.references :staff_member, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :availabilities, [ :staff_member_id, :day_of_week, :active ]
    add_check_constraint :availabilities, "day_of_week BETWEEN 0 AND 6", name: "availabilities_valid_day"
    add_check_constraint :availabilities, "start_time < end_time", name: "availabilities_ordered_times"
    add_check_constraint :availabilities, "active IN (0, 1)", name: "availabilities_valid_active"
  end
end
