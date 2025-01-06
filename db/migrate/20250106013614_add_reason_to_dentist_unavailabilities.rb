class AddReasonToDentistUnavailabilities < ActiveRecord::Migration[7.2]
  def change
    add_column :dentist_unavailabilities, :reason, :string
  end
end
