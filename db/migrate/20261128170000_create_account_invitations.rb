# Invitations to join a team account. At most one pending (not yet accepted)
# invitation per account and email address.
class CreateAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :account_invitations, if_not_exists: true do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }, index: true
      t.string :email_address, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :account_invitations, :token, unique: true, if_not_exists: true
    add_index :account_invitations, [ :account_id, :email_address ], unique: true,
      where: "accepted_at IS NULL", name: "index_account_invitations_pending_unique", if_not_exists: true
  end
end
