class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.text :description
      t.integer :duration_minutes, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :services, "lower(name)", unique: true, name: "index_services_on_normalized_name"
    add_check_constraint :services, "duration_minutes > 0", name: "services_positive_duration"
    add_check_constraint :services, "price >= 0", name: "services_nonnegative_price"
    add_check_constraint :services, "active IN (0, 1)", name: "services_valid_active"
  end
end
