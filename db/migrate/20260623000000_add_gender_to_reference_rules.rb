class AddGenderToReferenceRules < ActiveRecord::Migration[8.1]
  def change
    add_column :reference_rules, :gender, :string
    add_index  :reference_rules, :gender
  end
end
