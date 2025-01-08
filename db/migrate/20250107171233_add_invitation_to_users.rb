class AddInvitationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :invitation_token, :string
    add_column :users, :invitation_sent_at, :datetime
  end
end
