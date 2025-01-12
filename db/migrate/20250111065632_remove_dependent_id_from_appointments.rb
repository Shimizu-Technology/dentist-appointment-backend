class RemoveDependentIdFromAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_dependent, :boolean, default: false, null: false
    add_reference :users, :parent_user, foreign_key: { to_table: :users }, null: true
    add_column :users, :date_of_birth, :date
  end
end
