class AddLoincAndLocalCodeToReferenceRules < ActiveRecord::Migration[8.1]
  def change
    add_column :reference_rules, :local_code, :string
    add_index :reference_rules, :local_code
  end
end
