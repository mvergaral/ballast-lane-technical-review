# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-01-15

### Added
- **Authentication System**: Devise integration for user authentication
- **JWT Token Management**: Devise JWT for secure token-based authentication
- **Authorization System**: Pundit integration for role-based access control
- **Testing Framework**: RSpec and FactoryBot for comprehensive testing
- **User Model**: Complete user authentication with email/password
- **Authentication Endpoints**: Register, login, and logout API endpoints
- **Protected Routes**: Example protected endpoints with JWT authentication
- **JWT Token Revocation**: Secure token management with denylist
- **Comprehensive Testing**: User model tests and authentication specs
- **Authentication Documentation**: Complete guide for auth implementation

### Technical Details
- **Devise**: User authentication and session management
- **Devise JWT**: JWT token generation and validation
- **Pundit**: Authorization policies and access control
- **RSpec**: Testing framework with FactoryBot factories
- **JWT Denylist**: Token revocation strategy for security

### API Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User authentication
- `DELETE /api/auth/logout` - Token revocation
- `GET /api/users` - Protected user information
- `GET /api/users/:id` - Protected user details

## [1.0.0] - 2024-01-15

### Added
- Initial Rails API project setup with Ruby 3.4.1 and Rails 8.0.2
- PostgreSQL database configuration
- CORS configuration to allow communication between frontend and backend
- React frontend with Vite and Tailwind CSS
- Health check endpoint at `/api/health`
- Development script `dev.sh` to start both servers simultaneously
- Complete asdf configuration for Ruby version management
- Comprehensive README with installation and usage instructions
- Appropriate .gitignore file for the project
- Kamal configuration for deployment
- Root package.json for project-wide scripts

### Technical Details
- **Backend**: Rails 8.0.2 in API mode with PostgreSQL
- **Frontend**: React 18 with Vite and Tailwind CSS
- **Database**: PostgreSQL configured and migrated
- **CORS**: Configured for local development
- **Development**: Automated scripts to facilitate development

### Infrastructure
- Dockerfile included for containerization
- Kamal configuration for deployment
- Organized and scalable project structure 