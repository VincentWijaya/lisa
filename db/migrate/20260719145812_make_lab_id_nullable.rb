class MakeLabIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :specimens, :lab_id, true
  end
end
