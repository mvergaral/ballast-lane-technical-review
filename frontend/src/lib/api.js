import axios from 'axios'
import toast from 'react-hot-toast'
import Cookies from 'js-cookie'

// Configure axios defaults
const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  withCredentials: true,
})

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

// ===== AUTH API =====
export const authAPI = {
  login: (credentials) => api.post('/auth/login', { user: credentials }),
  register: (userData) => api.post('/auth/register', { user: userData }),
  logout: () => api.delete('/auth/logout'),
}

// ===== DASHBOARD API =====
export const dashboardAPI = {
  getStats: () => api.get('/dashboard'),
}

// ===== BOOKS API =====
export const booksAPI = {
  getAll: (params = {}) => api.get('/books', { params }),
  getOne: (id) => api.get(`/books/${id}`),
  create: (bookData) => api.post('/books', { book: bookData }),
  update: (id, bookData) => api.put(`/books/${id}`, { book: bookData }),
  delete: (id) => api.delete(`/books/${id}`),
  search: (query, params = {}) => api.get('/books/search', { params: { q: query, ...params } }),
  searchSuggestions: (query) => api.get('/books/search/suggestions', { params: { q: query } }),
  advancedSearch: (filters) => api.get('/books/search/advanced', { params: filters }),
}

// ===== BORROWINGS API =====
export const borrowingsAPI = {
  getAll: (params = {}) => api.get('/borrowings', { params }),
  getOne: (id) => api.get(`/borrowings/${id}`),
  create: (borrowingData) => api.post('/borrowings', { borrowing: borrowingData }),
  update: (id, borrowingData) => api.put(`/borrowings/${id}`, { borrowing: borrowingData }),
  delete: (id) => api.delete(`/borrowings/${id}`),
  returnBook: (id) => api.post(`/borrowings/${id}/return_book`),
}

// ===== USERS API =====
export const usersAPI = {
  getAll: (params = {}) => api.get('/users', { params }),
  getOne: (id) => api.get(`/users/${id}`),
}

// Default export
export default api 