class AddAiSummaryToWorks < ActiveRecord::Migration[8.1]
  def change
    add_column :works, :ai_summary, :text
  end
end
