# Ballast Lane Technical Review

A comprehensive library management system built with Rails API and React frontend, featuring user authentication, book management, borrowing system, and role-based authorization.

## User Stories

### 1. Search and Borrow a Book

**As a** Member  
**I want to** search the catalog and borrow a book if available  
**So that** I can read it for up to 14 days without visiting the physical library.

**Acceptance Criteria:**
- The system should return books that match the search term in title or author.
- Members can only borrow books with available copies.
- Borrowed books set a `due_at` date 14 days from today.
- Members cannot borrow the same book again without returning it first.

---

### 2. Return a Borrowed Book

**As a** Member  
**I want to** return a borrowed book  
**So that** I can avoid late returns and free up the copy for other users.

**Acceptance Criteria:**
- Returning a book sets the `returned_at` date and increases the available copies.
- Returning a book after the due date flags it for a late return.
- Attempting to return a book not borrowed by the user results in an error.

---

### 3. Manage the Catalog

**As a** Librarian  
**I want to** create, edit, and delete book records  
**So that** the catalog remains accurate and useful for members.

**Acceptance Criteria:**
- Only librarians can access endpoints to manage books.
- ISBN must be unique and properly formatted.
- Books can be edited to update metadata like genre or author.
- Deletion is blocked if the book has active borrowings.

## Features

- **User Authentication & Authorization** - JWT-based authentication with role management (Librarian/Member)
- **Book Management** - Full CRUD operations with search functionality and availability tracking
- **Borrowing System** - Book checkout/return with due date management and overdue tracking
- **Search & Filtering** - Advanced search with pagination and full-text search capabilities
- **Responsive UI** - Modern React frontend with Tailwind CSS styling

## Technology Stack

### Backend (Rails API)
- **Rails 8.0.2** - Ruby web framework for building the API
- **Ruby 3.4.1**
- **PostgreSQL**
- **Devise** - Authentication solution for user management
- **Devise-JWT** - JWT token authentication for stateless API sessions
- **Pundit** - Authorization framework for role-based access control
- **Kaminari** - Pagination library for efficient data loading
- **Active Model Serializers** - JSON serialization for consistent API responses
- **RSpec** - Testing framework with FactoryBot and Faker for test data

### Frontend (React)
- **React 19.1.0**
- **Vite 7.0.4**
- **React Router Dom 7.7.1**
- **TanStack Query 5.83.0**
- **React Hook Form 7.61.1**
- **Zod 4.0.9**
- **Tailwind CSS 4.1.11**
- **Zustand 5.0.6**
- **Axios 1.11.0**
- **Framer Motion 12.23.9** - Animation library for smooth UI transitions

## Prerequisites

- **Ruby 3.4.1** - Use rbenv or rvm to manage Ruby versions
- **Rails 8.0.2** - Installed via the ruby gem
- **PostgreSQL 12+** - Database server
- **Node.js 18+** - JavaScript runtime for frontend development
- **pnpm or yarn** - Package manager for JavaScript dependencies

## Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/mvergaral/ballast-lane-technical-review
cd ballast-lane-technical-review
```

### 2. Backend Setup

#### Install Ruby Dependencies
```bash
bundle install
```

#### Database Configuration
Ensure PostgreSQL is running, then:
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 3. Frontend Setup

#### Navigate to Frontend Directory
```bash
cd frontend
```

#### Install Node Dependencies
```bash
pnpm install
```

## Running the Application

### Option 1: Automated Development Script
Run both backend and frontend simultaneously:
```bash
chmod +x dev.sh
./dev.sh
```

### Option 2: Manual Setup

#### Start the Rails API Server
```bash
rails server -p 3001
```

#### Start the React Development Server
```bash
cd frontend
pnpm run dev
```

### Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/api/health/index

## Testing

### Backend Tests
```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Run specific test files
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
bundle exec rspec spec/policies/
```

### Frontend Tests
```bash
cd frontend
pnpm run test
```

## Project Structure

```
ballast-lane-technical-review/
├── app/                    # Rails application code
│   ├── controllers/api/    # API controllers
│   ├── models/            # ActiveRecord models
│   ├── policies/          # Pundit authorization policies
│   └── serializers/       # JSON serializers
├── frontend/              # React application
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── pages/         # Page components
│   │   ├── hooks/         # Custom React hooks
│   │   ├── services/      # API service layer
│   │   └── lib/          # Utility functions
│   └── public/           # Static assets
├── spec/                 # RSpec test files
├── db/                   # Database migrations and seeds
└── config/               # Rails configuration
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `DELETE /api/auth/logout` - User logout

### Books
- `GET /api/books` - List all books with pagination
- `GET /api/books/:id` - Get book details
- `POST /api/books` - Create new book (Librarian only)
- `PUT /api/books/:id` - Update book (Librarian only)
- `DELETE /api/books/:id` - Delete book (Librarian only)
- `GET /api/books/search` - Search books with query

### Borrowings
- `GET /api/borrowings` - List borrowings
- `POST /api/borrowings` - Create new borrowing
- `PUT /api/borrowings/:id` - Update borrowing
- `DELETE /api/borrowings/:id` - Delete borrowing
- `POST /api/borrowings/:id/return_book` - Return borrowed book

### Users
- `GET /api/users` - List users (Librarian only)
- `GET /api/users/:id` - Get user details

## User Roles

### Librarian
- Full access to all system features
- Can manage books (create, update, delete)
- Can view all users and borrowings

### Member
- Can browse and search books
- Can borrow and return books
- Can view their own borrowing history

## Security Features

- JWT-based stateless authentication
- Role-based authorization with Pundit
- CORS configuration for frontend integration
- Input validation and sanitization
- Secure password handling with Devise

## Additional Information

### Database Schema
The application uses PostgreSQL with the following main entities:
- **Users** - Authentication and role management
- **Books** - Book catalog with availability tracking
- **Borrowings** - Transaction records with due dates

### Code Quality
- **Test Coverage**: 93%+ line coverage with RSpec
- **Linting**: ESLint for JavaScript/React code
- **Code Style**: Consistent formatting and naming conventions

## Generative AI tools section

to see the output of the generative AI tool section, please refer to the [CODE.md](CODE.md) file.
