class AddStaffToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :staff, :boolean
  end
end
