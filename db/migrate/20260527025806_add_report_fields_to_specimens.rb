class AddReportFieldsToSpecimens < ActiveRecord::Migration[8.1]
  def change
    add_column :specimens, :referring_doctor, :string
    add_column :specimens, :affiliation, :string
    add_column :specimens, :patient_address, :text
    add_column :specimens, :responsible_doctor, :string
  end
end
