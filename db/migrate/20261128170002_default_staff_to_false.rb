# Staff is opt-in: existing and new users are not staff unless an operator
# grants it (bin/rails staff:grant[email]).
class DefaultStaffToFalse < ActiveRecord::Migration[8.1]
  def up
    change_column_default :users, :staff, from: nil, to: false
    execute "UPDATE users SET staff = FALSE WHERE staff IS NULL"
    change_column_null :users, :staff, false
  end

  def down
    change_column_null :users, :staff, true
    change_column_default :users, :staff, from: false, to: nil
  end
end
