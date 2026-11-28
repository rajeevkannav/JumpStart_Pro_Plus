class AddSudoAtToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :sudo_at, :datetime
  end
end
