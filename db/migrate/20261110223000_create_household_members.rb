class CreateHouseholdMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :household_members do |t|
      t.string :name, null: false
      t.string :username, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :household_members, "lower(username)", unique: true
  end
end
