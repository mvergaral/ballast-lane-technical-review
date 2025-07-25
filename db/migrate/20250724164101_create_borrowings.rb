class CreateBorrowings < ActiveRecord::Migration[8.0]
  def change
    create_table :borrowings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.datetime :due_date, null: false
      t.datetime :returned_at

      t.timestamps
    end
    
    add_index :borrowings, [:user_id, :book_id, :returned_at], unique: true, where: "returned_at IS NULL"
    add_index :borrowings, :due_date
    add_index :borrowings, :returned_at
  end
end
