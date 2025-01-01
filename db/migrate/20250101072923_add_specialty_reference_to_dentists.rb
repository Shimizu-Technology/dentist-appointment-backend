class AddSpecialtyReferenceToDentists < ActiveRecord::Migration[7.2]
  def change
    add_reference :dentists, :specialty, null: true, foreign_key: true
    remove_column :dentists, :specialty, :string
  end
end
