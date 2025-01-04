class CreateClosedDays < ActiveRecord::Migration[7.2]
  def change
    create_table :closed_days do |t|
      t.date :date, null: false
      t.string :reason

      t.timestamps
    end

    add_index :closed_days, :date, unique: true
  end
end
