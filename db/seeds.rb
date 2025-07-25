# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

puts "Creating users..."

# Usuarios de demostración que coinciden con las credenciales mostradas en el frontend
librarian = User.find_or_create_by!(email: 'librarian@library.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :librarian
end

member = User.find_or_create_by!(email: 'member@library.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :member
end

puts "Users created: #{librarian.email} (librarian), #{member.email} (member)"

puts "Creating books..."

books_data = [
  {
    title: 'The Ruby Programming Language',
    author: 'David Flanagan',
    genre: 'Programming',
    isbn: '9780596516178',
    total_copies: 3,
    available_copies: 3
  },
  {
    title: 'Rails 5 Test Prescriptions',
    author: 'Noel Rappin',
    genre: 'Programming',
    isbn: '9781680502508',
    total_copies: 2,
    available_copies: 2
  },
  {
    title: 'Clean Code',
    author: 'Robert C. Martin',
    genre: 'Programming',
    isbn: '9780132350884',
    total_copies: 4,
    available_copies: 4
  },
  {
    title: 'Design Patterns',
    author: 'Erich Gamma',
    genre: 'Programming',
    isbn: '9780201633610',
    total_copies: 2,
    available_copies: 2
  },
  {
    title: 'The Pragmatic Programmer',
    author: 'Andrew Hunt',
    genre: 'Programming',
    isbn: '9780135957059',
    total_copies: 3,
    available_copies: 3
  },
  {
    title: 'Harry Potter and the Philosopher\'s Stone',
    author: 'J.K. Rowling',
    genre: 'Fantasy',
    isbn: '9780747532699',
    total_copies: 5,
    available_copies: 5
  },
  {
    title: 'The Lord of the Rings',
    author: 'J.R.R. Tolkien',
    genre: 'Fantasy',
    isbn: '9780547928210',
    total_copies: 3,
    available_copies: 3
  },
  {
    title: '1984',
    author: 'George Orwell',
    genre: 'Dystopian',
    isbn: '9780451524935',
    total_copies: 2,
    available_copies: 2
  },
  {
    title: 'Cien años de soledad',
    author: 'Gabriel García Márquez',
    genre: 'Realismo Mágico',
    isbn: '9788420471839',
    total_copies: 4,
    available_copies: 4
  },
  {
    title: 'Don Quijote de la Mancha',
    author: 'Miguel de Cervantes',
    genre: 'Clásico',
    isbn: '9788491050241',
    total_copies: 3,
    available_copies: 3
  }
]

books_data.each do |book_data|
  Book.find_or_create_by!(isbn: book_data[:isbn]) do |book|
    book.title = book_data[:title]
    book.author = book_data[:author]
    book.genre = book_data[:genre]
    book.total_copies = book_data[:total_copies]
    book.available_copies = book_data[:available_copies]
  end
end

puts "#{books_data.length} books created"

puts "Creating sample borrowings..."

# Solo crear préstamos si no existen ya y si hay copias disponibles
book = Book.find_by(isbn: '9780596516178') # The Ruby Programming Language
if book && book.available_copies > 0 && !Borrowing.exists?(user: member, book: book, returned_at: nil)
  borrowing = Borrowing.create!(
    user: member,
    book: book,
    borrowed_at: 1.week.ago,
    due_date: 1.week.from_now,
    returned_at: nil
  )
  book.update!(available_copies: book.available_copies - 1)
  puts "Created active borrowing: #{book.title} by #{member.email}"
end

# Crear un préstamo vencido
overdue_book = Book.find_by(isbn: '9781680502508') # Rails 5 Test Prescriptions
if overdue_book && overdue_book.available_copies > 0 && !Borrowing.exists?(user: member, book: overdue_book, returned_at: nil)
  borrowing = Borrowing.create!(
    user: member,
    book: overdue_book,
    borrowed_at: 3.weeks.ago,
    due_date: 1.week.ago,
    returned_at: nil
  )
  overdue_book.update!(available_copies: overdue_book.available_copies - 1)
  puts "Created overdue borrowing: #{overdue_book.title} by #{member.email}"
end

# Crear un préstamo devuelto
returned_book = Book.find_by(isbn: '9780132350884') # Clean Code
if returned_book && !Borrowing.exists?(user: member, book: returned_book, returned_at: [1.week.ago..Time.current])
  borrowing = Borrowing.create!(
    user: member,
    book: returned_book,
    borrowed_at: 1.month.ago,
    due_date: 3.weeks.ago,
    returned_at: 1.week.ago
  )
  puts "Created returned borrowing: #{returned_book.title} by #{member.email}"
end

puts "Sample borrowings created"

puts "Database seeded successfully!"
