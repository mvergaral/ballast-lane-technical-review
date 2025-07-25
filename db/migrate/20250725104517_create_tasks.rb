class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.date :due_date, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
