class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email_address, null: false
      t.string :phone
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_normalized_email"
    add_check_constraint :users, "role IN (0, 1)", name: "users_valid_role"
    add_check_constraint :users, "active IN (0, 1)", name: "users_valid_active"
  end
end
