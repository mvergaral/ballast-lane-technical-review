# Ballast Lane Technical Review

A comprehensive library management system built with Rails API and React frontend, featuring user authentication, book management, borrowing system, and role-based authorization.

## 🚀 Features

- **User Authentication & Authorization** - JWT-based authentication with role management (Librarian/Member)
- **Book Management** - Full CRUD operations with search functionality and availability tracking
- **Borrowing System** - Book checkout/return with due date management and overdue tracking
- **Search & Filtering** - Advanced search with pagination and full-text search capabilities
- **Responsive UI** - Modern React frontend with Tailwind CSS styling

## 🛠 Technology Stack

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

## 📋 Prerequisites

- **Ruby 3.4.1** - Use rbenv or rvm to manage Ruby versions
- **Rails 8.0.2** - Installed via the ruby gem
- **PostgreSQL 12+** - Database server
- **Node.js 18+** - JavaScript runtime for frontend development
- **pnpm or yarn** - Package manager for JavaScript dependencies

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
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

#### Environment Variables
Create a `.env` file in the root directory:
```bash
DATABASE_URL=postgresql://username:password@localhost/ballast_lane_development
DEVISE_JWT_SECRET_KEY=your_jwt_secret_key_here
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

#### Environment Configuration
Create a `.env` file in the frontend directory:
```bash
VITE_API_BASE_URL=http://localhost:3001/api
```

## 🚦 Running the Application

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

## 🧪 Testing

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

## 📁 Project Structure

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

## 🔑 API Endpoints

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

## 👥 User Roles

### Librarian
- Full access to all system features
- Can manage books (create, update, delete)
- Can view all users and borrowings

### Member
- Can browse and search books
- Can borrow and return books
- Can view their own borrowing history

## 🔒 Security Features

- JWT-based stateless authentication
- Role-based authorization with Pundit
- CORS configuration for frontend integration
- Input validation and sanitization
- Secure password handling with Devise

## 📊 Additional Information

### Database Schema
The application uses PostgreSQL with the following main entities:
- **Users** - Authentication and role management
- **Books** - Book catalog with availability tracking
- **Borrowings** - Transaction records with due dates

### Code Quality
- **Test Coverage**: 93%+ line coverage with RSpec
- **Linting**: ESLint for JavaScript/React code
- **Code Style**: Consistent formatting and naming conventions


