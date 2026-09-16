class CreateStaffMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_members do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email_address
      t.string :phone
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :staff_members, "lower(email_address)", unique: true, name: "index_staff_members_on_normalized_email"
    add_check_constraint :staff_members, "active IN (0, 1)", name: "staff_members_valid_active"
  end
end
