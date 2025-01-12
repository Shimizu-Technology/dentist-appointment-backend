class DropDependentsTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :dependents, if_exists: true
  end
end
