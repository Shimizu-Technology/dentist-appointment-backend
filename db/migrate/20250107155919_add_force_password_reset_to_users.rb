class AddForcePasswordResetToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :force_password_reset, :boolean, default: false, null: false
  end
end
