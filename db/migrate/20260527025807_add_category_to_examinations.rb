class AddCategoryToExaminations < ActiveRecord::Migration[8.1]
  def change
    add_column :examinations, :category, :string
    add_index :examinations, :category
  end
end
