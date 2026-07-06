class AddFormulaFieldsToReferenceRules < ActiveRecord::Migration[8.1]
  def change
    add_column :reference_rules, :formula_expression, :text
    add_column :reference_rules, :formula_inputs,    :jsonb, default: [], null: false
  end
end
