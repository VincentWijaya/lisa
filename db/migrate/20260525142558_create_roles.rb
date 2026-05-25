class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.references :resource, polymorphic: true

      t.timestamps
    end

    add_index :roles, [ :name, :resource_type, :resource_id ], unique: true
    add_index :roles, :name
  end
end
