class CreateExaminations < ActiveRecord::Migration[8.1]
  def change
    create_table :examinations do |t|
      t.string :name,                null: false
      t.string :code
      t.text :description
      t.string :default_unit
      t.string :default_result_type
      t.string :status,              null: false, default: "active"
      t.string :specimen_type
      t.string :label_group

      t.timestamps
    end

    add_index :examinations, :code, unique: true, where: "code IS NOT NULL"
    add_index :examinations, :status
  end
end
