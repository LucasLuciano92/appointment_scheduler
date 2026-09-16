class CreateServiceOfferings < ActiveRecord::Migration[8.1]
  def change
    create_table :service_offerings do |t|
      t.references :staff_member, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :service_offerings, [ :staff_member_id, :service_id ], unique: true
    add_check_constraint :service_offerings, "active IN (0, 1)", name: "service_offerings_valid_active"
  end
end
