import { create } from 'zustand'
import { authAPI } from '@/lib/api'

const useAuthStore = create((set, get) => ({
  // State
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,

  // Actions
  setUser: (user) => set({ user, isAuthenticated: !!user }),
  
  setError: (error) => set({ error }),
  
  clearError: () => set({ error: null }),

  login: async (credentials) => {
    try {
      set({ isLoading: true, error: null })
      
      const response = await authAPI.login(credentials)
      const { user } = response.data
      
      // Extract JWT token from Authorization header
      const authHeader = response.headers.authorization
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7) // Remove 'Bearer ' prefix
        localStorage.setItem('auth_token', token)
      }
      
      // Store user data
      localStorage.setItem('user', JSON.stringify(user))
      
      set({ 
        user, 
        isAuthenticated: true, 
        isLoading: false,
        error: null 
      })
      
      return { success: true, user }
    } catch (error) {
      const errorMessage = error.response?.data?.message || 'Login failed'
      set({ 
        user: null, 
        isAuthenticated: false, 
        isLoading: false,
        error: errorMessage 
      })
      return { success: false, error: errorMessage }
    }
  },

  register: async (userData) => {
    try {
      set({ isLoading: true, error: null })
      
      const response = await authAPI.register(userData)
      const { user } = response.data
      
      // Extract JWT token from Authorization header
      const authHeader = response.headers.authorization
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7) // Remove 'Bearer ' prefix
        localStorage.setItem('auth_token', token)
      }
      
      // Store user data
      localStorage.setItem('user', JSON.stringify(user))
      
      set({ 
        user, 
        isAuthenticated: true, 
        isLoading: false,
        error: null 
      })
      
      return { success: true, user }
    } catch (error) {
      const errorMessage = error.response?.data?.message || error.response?.data?.errors?.[0] || 'Registration failed'
      set({ 
        user: null, 
        isAuthenticated: false, 
        isLoading: false,
        error: errorMessage 
      })
      return { success: false, error: errorMessage }
    }
  },

  logout: async () => {
    try {
      await authAPI.logout()
    } catch (error) {
      // Continue with logout even if API call fails
      console.warn('Logout API call failed:', error)
    } finally {
      // Clear local storage and state
      localStorage.removeItem('user')
      localStorage.removeItem('auth_token')
      set({ 
        user: null, 
        isAuthenticated: false, 
        isLoading: false,
        error: null 
      })
    }
  },

  checkAuth: () => {
    try {
      const userData = localStorage.getItem('user')
      const authToken = localStorage.getItem('auth_token')
      
      if (userData && authToken) {
        const user = JSON.parse(userData)
        set({ 
          user, 
          isAuthenticated: true, 
          isLoading: false 
        })
      } else {
        // Clear any partial data if either is missing
        localStorage.removeItem('user')
        localStorage.removeItem('auth_token')
        set({ 
          user: null, 
          isAuthenticated: false, 
          isLoading: false 
        })
      }
    } catch (error) {
      console.error('Error checking auth:', error)
      localStorage.removeItem('user')
      localStorage.removeItem('auth_token')
      set({ 
        user: null, 
        isAuthenticated: false, 
        isLoading: false 
      })
    }
  },

  // Utility getters
  isLibrarian: () => {
    const { user } = get()
    return user?.role === 'librarian'
  },

  isMember: () => {
    const { user } = get()
    return user?.role === 'member'
  },

  getUserRole: () => {
    const { user } = get()
    return user?.role || null
  },

  getUserName: () => {
    const { user } = get()
    return user?.email?.split('@')[0] || 'User'
  },
}))

export default useAuthStore 