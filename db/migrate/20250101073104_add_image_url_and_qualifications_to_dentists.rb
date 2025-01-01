class AddImageUrlAndQualificationsToDentists < ActiveRecord::Migration[7.2]
  def change
    add_column :dentists, :image_url, :string
    add_column :dentists, :qualifications, :text
  end
end
