class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string, if_not_exists: true
    add_column :users, :otp_enabled_at, :datetime, if_not_exists: true
  end
end
