import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Users as UsersIcon, Search, User, Book, AlertTriangle } from 'lucide-react'
import MainLayout from '@/components/layout/MainLayout'
import Card from '@/components/ui/Card'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import useAuthStore from '@/store/authStore'
import { usersAPI } from '@/lib/api'

const Users = () => {
  const { isLibrarian } = useAuthStore()
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [roleFilter, setRoleFilter] = useState('all') // 'all', 'librarian', 'member'
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  // Redirect non-librarians to dashboard
  useEffect(() => {
    if (!isLibrarian()) {
      navigate('/dashboard')
      return
    }
  }, [isLibrarian, navigate])

  useEffect(() => {
    if (isLibrarian()) {
      fetchUsers()
    }
  }, [currentPage, roleFilter, isLibrarian])

  // Don't render anything for non-librarians
  if (!isLibrarian()) {
    return null
  }

  const fetchUsers = async (page = 1) => {
    try {
      setLoading(true)
      const params = { 
        page, 
        per_page: 12,
        role: roleFilter !== 'all' ? roleFilter : undefined,
        search: searchQuery || undefined
      }
      
      const response = await usersAPI.getAll(params)
      const { users: usersData, pagination } = response.data
      
      setUsers(usersData || [])
      setCurrentPage(pagination?.current_page || 1)
      setTotalPages(pagination?.total_pages || 1)
    } catch (error) {
      console.error('Error fetching users:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = () => {
    setCurrentPage(1)
    fetchUsers(1)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-gray-600">Manage library users and their information</p>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <div className="flex">
              <div className="flex-1">
                <Input
                  type="text"
                  placeholder="Search users by email..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                  leftIcon={Search}
                  className="rounded-r-none"
                />
              </div>
              <Button onClick={handleSearch} className="rounded-l-none">
                Search
              </Button>
            </div>
          </div>

          {/* Role Filter */}
          <div className="sm:w-48">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Roles</option>
              <option value="librarian">Librarians</option>
              <option value="member">Members</option>
            </select>
          </div>
        </div>

        {/* Users Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full spin"></div>
            <p className="ml-3 text-sm text-muted-foreground">Loading users...</p>
          </div>
        ) : users.length > 0 ? (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {users.map((user) => (
                <UserCard key={user.id} user={user} />
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-center space-x-2">
                <Button
                  variant="outline"
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  disabled={currentPage === 1}
                >
                  Previous
                </Button>
                
                <span className="px-4 py-2 text-sm text-gray-600">
                  Page {currentPage} of {totalPages}
                </span>
                
                <Button
                  variant="outline"
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={currentPage === totalPages}
                >
                  Next
                </Button>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <UsersIcon className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">
              {searchQuery ? 'No users found' : 'No users yet'}
            </h3>
            <p className="mt-1 text-sm text-gray-500">
              {searchQuery
                ? 'Try adjusting your search terms'
                : 'Users will appear here when they register'
              }
            </p>
          </div>
        )}
      </div>
    </MainLayout>
  )
}

const UserCard = ({ user }) => {
  const isLibrarian = user.role === 'librarian'
  const hasOverdueBooks = user.overdue_books_count > 0

  return (
    <Card className="h-full">
      <Card.Body className="p-6">
        <div className="flex flex-col h-full">
          {/* User Avatar and Basic Info */}
          <div className="flex items-center mb-4">
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <User className="h-6 w-6 text-blue-600" />
            </div>
            <div className="ml-3 flex-1">
              <h3 className="text-lg font-medium text-gray-900">
                {user.email.split('@')[0]}
              </h3>
              <p className="text-sm text-gray-500">{user.email}</p>
            </div>
          </div>

          {/* Role Badge */}
          <div className="mb-4">
            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
              isLibrarian 
                ? 'bg-purple-100 text-purple-800' 
                : 'bg-blue-100 text-blue-800'
            }`}>
              {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
            </span>
          </div>

          {/* Statistics */}
          <div className="flex-1 space-y-3">
            {/* Current Borrowings */}
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center">
                <Book className="h-4 w-4 text-gray-400 mr-2" />
                <span className="text-sm text-gray-600">Active Borrowings</span>
              </div>
              <span className="text-sm font-medium text-gray-900">
                {user.active_borrowings_count || 0}
              </span>
            </div>

            {/* Overdue Books */}
            {hasOverdueBooks && (
              <div className="flex items-center justify-between p-3 bg-red-50 rounded-lg">
                <div className="flex items-center">
                  <AlertTriangle className="h-4 w-4 text-red-500 mr-2" />
                  <span className="text-sm text-red-600">Overdue Books</span>
                </div>
                <span className="text-sm font-medium text-red-700">
                  {user.overdue_books_count}
                </span>
              </div>
            )}

            {/* Total Borrowings */}
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-sm text-gray-600">Total Borrowings</span>
              <span className="text-sm font-medium text-gray-900">
                {user.total_borrowings_count || 0}
              </span>
            </div>

            {/* Member Since */}
            <div className="pt-2 border-t border-gray-200">
              <p className="text-xs text-gray-500">
                Member since {new Date(user.created_at).toLocaleDateString()}
              </p>
            </div>
          </div>
        </div>
      </Card.Body>
    </Card>
  )
}

export default Users 