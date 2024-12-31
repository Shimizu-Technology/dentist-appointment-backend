class AddInsuranceInfoToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :provider_name, :string
    add_column :users, :policy_number, :string
    add_column :users, :plan_type, :string
  end
end
