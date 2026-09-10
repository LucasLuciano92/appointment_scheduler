class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :service_offering, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :appointments, [ :service_offering_id, :status, :starts_at ], name: "index_appointments_on_offering_status_start"
    add_check_constraint :appointments, "status IN (0, 1, 2)", name: "appointments_valid_status"
    add_check_constraint :appointments, "starts_at < ends_at", name: "appointments_ordered_times"
  end
end
