import { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import useAuthStore from '@/store/authStore'
import Login from '@/pages/Login'
import Register from '@/pages/Register'
import Dashboard from '@/pages/Dashboard'
import Books from '@/pages/Books'
import Borrowings from '@/pages/Borrowings'
import Users from '@/pages/Users'

function App() {
  const { checkAuth, isAuthenticated, isLoading, isLibrarian } = useAuthStore()

  useEffect(() => {
    // Check authentication status on app load
    checkAuth()
  }, [checkAuth])

  // Show loading screen while checking authentication
  if (isLoading) {
    return (
      <div className="min-h-screen flex-center bg-background">
        <div className="text-center">
          <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full spin mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      <Routes>
        {/* Public routes */}
        <Route
          path="/login"
          element={
            !isAuthenticated ? (
              <Login />
            ) : (
              <Navigate to="/dashboard" replace />
            )
          }
        />
        
        <Route
          path="/register"
          element={
            !isAuthenticated ? (
              <Register />
            ) : (
              <Navigate to="/dashboard" replace />
            )
          }
        />

        {/* Protected routes */}
        <Route
          path="/dashboard"
          element={
            isAuthenticated ? (
              <Dashboard />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        <Route
          path="/books"
          element={
            isAuthenticated ? (
              <Books />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        <Route
          path="/borrowings"
          element={
            isAuthenticated ? (
              <Borrowings />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        <Route
          path="/users"
          element={
            isAuthenticated && isLibrarian() ? (
              <Users />
            ) : isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        {/* Default route */}
        <Route
          path="/"
          element={
            isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />

        {/* 404 page */}
        <Route
          path="*"
          element={
            <div className="min-h-screen flex-center">
              <div className="text-center">
                <h1 className="text-6xl font-bold text-blue-600 mb-4">404</h1>
                <h2 className="text-2xl font-semibold text-gray-900 mb-2">
                  Page not found
                </h2>
                <p className="text-gray-600 mb-6">
                  The page you're looking for doesn't exist.
                </p>
                <a
                  href="/"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  Go back home
                </a>
              </div>
            </div>
          }
        />
      </Routes>
    </div>
  )
}

export default App
