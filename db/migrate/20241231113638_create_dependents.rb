class CreateDependents < ActiveRecord::Migration[7.2]
  def change
    create_table :dependents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.date :date_of_birth

      t.timestamps
    end
  end
end
