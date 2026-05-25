class AddReferenceRuleFkToExaminationResults < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :examination_results, :reference_rules
  end
end
