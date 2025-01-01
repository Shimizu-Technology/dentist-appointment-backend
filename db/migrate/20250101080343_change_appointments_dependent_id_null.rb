class ChangeAppointmentsDependentIdNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :appointments, :dependent_id, true
  end
end
