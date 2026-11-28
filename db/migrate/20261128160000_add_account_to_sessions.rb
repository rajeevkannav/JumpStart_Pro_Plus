# The account selected in a session. Nullable: nil means "use the user's
# personal account". Deleting an account clears the selection.
class AddAccountToSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :sessions, :account, null: true, foreign_key: { on_delete: :nullify }, if_not_exists: true
  end
end
