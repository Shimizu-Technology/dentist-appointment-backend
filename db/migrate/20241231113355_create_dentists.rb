class CreateDentists < ActiveRecord::Migration[7.2]
  def change
    create_table :dentists do |t|
      t.string :first_name
      t.string :last_name
      t.string :specialty

      t.timestamps
    end
  end
end
