class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.string :api_token
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :api_token, unique: true
  end
end
