class AddAiSummaryToSpecimens < ActiveRecord::Migration[8.1]
  def change
    add_column :specimens, :ai_summary, :text
  end
end
