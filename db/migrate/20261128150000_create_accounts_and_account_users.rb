class CreateAccountsAndAccountUsers < ActiveRecord::Migration[8.1]
  def up
    create_table :accounts, if_not_exists: true do |t|
      t.string :name, null: false
      t.boolean :personal, null: false, default: false
      t.references :owner, null: false, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end
    # At most one personal account per user.
    add_index :accounts, :owner_id, unique: true, where: "personal = true",
      name: "index_accounts_on_owner_id_personal", if_not_exists: true

    create_table :account_users, if_not_exists: true do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :role, null: false, default: "member"
      t.timestamps
    end
    add_index :account_users, [ :account_id, :user_id ], unique: true, if_not_exists: true

    # Data migration: give every existing user a personal account they own.
    execute <<~SQL.squish
      INSERT INTO accounts (name, personal, owner_id, created_at, updated_at)
      SELECT users.email_address, TRUE, users.id, NOW(), NOW()
      FROM users
      WHERE NOT EXISTS (
        SELECT 1 FROM accounts WHERE accounts.owner_id = users.id AND accounts.personal = TRUE
      )
    SQL

    execute <<~SQL.squish
      INSERT INTO account_users (account_id, user_id, role, created_at, updated_at)
      SELECT accounts.id, accounts.owner_id, 'owner', NOW(), NOW()
      FROM accounts
      WHERE accounts.personal = TRUE
        AND NOT EXISTS (
          SELECT 1 FROM account_users
          WHERE account_users.account_id = accounts.id AND account_users.user_id = accounts.owner_id
        )
    SQL
  end

  def down
    drop_table :account_users, if_exists: true
    drop_table :accounts, if_exists: true
  end
end
