class RemoveDependentReferenceFromAppointments < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :appointments, :dependents   # Only if the FK truly exists
    remove_reference  :appointments, :dependent, foreign_key: false
  end
end
