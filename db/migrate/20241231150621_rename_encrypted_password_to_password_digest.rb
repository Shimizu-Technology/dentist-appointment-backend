class RenameEncryptedPasswordToPasswordDigest < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :encrypted_password, :password_digest
  end
end
