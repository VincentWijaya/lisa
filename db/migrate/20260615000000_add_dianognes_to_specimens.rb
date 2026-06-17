class AddDianognesToSpecimens < ActiveRecord::Migration[8.1]
  def change
    add_column :specimens, :dianognes, :text
  end
end
