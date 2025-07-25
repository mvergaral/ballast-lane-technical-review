import { useState, useEffect } from 'react'
import { BookOpen, Calendar, Clock, CheckCircle, AlertTriangle, Search, RotateCcw } from 'lucide-react'
import toast from 'react-hot-toast'
import MainLayout from '@/components/layout/MainLayout'
import Card from '@/components/ui/Card'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import useAuthStore from '@/store/authStore'
import useDashboardRefresh from '@/hooks/useDashboardRefresh'
import { borrowingsAPI } from '@/lib/api'
import DeleteConfirmModal from '@/components/ui/DeleteConfirmModal'

// Helper functions moved outside components
const getBorrowingStatus = (borrowing) => {
  if (borrowing.returned_at) return 'returned'
  if (new Date(borrowing.due_date) < new Date()) return 'overdue'
  return 'active'
}

const getStatusBadge = (status) => {
  const badges = {
    active: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-400',
    overdue: 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-400',
    returned: 'bg-gray-100 text-gray-800 dark:bg-gray-900/40 dark:text-gray-400'
  }
  
  const labels = {
    active: 'Active',
    overdue: 'Overdue',
    returned: 'Returned'
  }

  return (
    <span className={`px-2 py-1 text-xs font-medium rounded-full ${badges[status]}`}>
      {labels[status]}
    </span>
  )
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString()
}

const Borrowings = () => {
  const { isLibrarian } = useAuthStore()
  const { invalidateDashboard } = useDashboardRefresh()
  const [borrowings, setBorrowings] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all') // 'all', 'active', 'overdue', 'returned'
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [selectedBorrowing, setSelectedBorrowing] = useState(null)
  const [showReturnModal, setShowReturnModal] = useState(false)

  useEffect(() => {
    fetchBorrowings()
  }, [currentPage, statusFilter])

  const fetchBorrowings = async (page = 1) => {
    try {
      setLoading(true)
      const params = { 
        page, 
        per_page: 10,
        status: statusFilter !== 'all' ? statusFilter : undefined,
        search: searchQuery || undefined
      }
      
      const response = await borrowingsAPI.getAll(params)
      const { borrowings: borrowingsData, pagination } = response.data
      
      setBorrowings(borrowingsData || [])
      setCurrentPage(pagination?.current_page || 1)
      setTotalPages(pagination?.total_pages || 1)
    } catch (error) {
      console.error('Error fetching borrowings:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = () => {
    setCurrentPage(1)
    fetchBorrowings(1)
  }

  const handleReturnBook = async () => {
    if (!selectedBorrowing) return

    try {
      await borrowingsAPI.returnBook(selectedBorrowing.id)
      setShowReturnModal(false)
      setSelectedBorrowing(null)
      fetchBorrowings(currentPage)
      
      // Invalidate dashboard to update statistics
      invalidateDashboard()
      
      // Show success toast
      toast.success(`Successfully returned "${selectedBorrowing.book?.title || 'book'}"!`, {
        duration: 4000,
        position: 'top-center',
        icon: '✅',
      })
    } catch (error) {
      console.error('Error returning book:', error)
      
      // Show error toast
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.errors?.[0] || 
                          'Failed to return book'
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-center',
      })
    }
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-foreground">Borrowings</h1>
          <p className="text-muted-foreground">
            {isLibrarian() ? 'Manage all library borrowings' : 'View your borrowing history'}
          </p>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-4">
          {/* Search */}
          <div className="flex-1">
            <div className="flex">
              <div className="flex-1">
                <Input
                  type="text"
                  placeholder="Search by book title, author, or user..."
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

          {/* Status Filter */}
          <div className="sm:w-48">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full px-3 py-2 border border-input rounded-lg bg-background text-foreground focus:ring-2 focus:ring-ring focus:border-transparent"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="overdue">Overdue</option>
              <option value="returned">Returned</option>
            </select>
          </div>
        </div>

        {/* Borrowings List */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full spin"></div>
            <p className="ml-3 text-sm text-muted-foreground">Loading borrowings...</p>
          </div>
        ) : borrowings.length > 0 ? (
          <>
            <div className="space-y-4">
              {borrowings.map((borrowing) => (
                <BorrowingCard
                  key={borrowing.id}
                  borrowing={borrowing}
                  onReturn={() => {
                    setSelectedBorrowing(borrowing)
                    setShowReturnModal(true)
                  }}
                  isLibrarian={isLibrarian()}
                />
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-center space-x-2">
                <Button
                  variant="outline"
                  onClick={() => {
                    setCurrentPage(prev => Math.max(prev - 1, 1))
                  }}
                  disabled={currentPage === 1}
                >
                  Previous
                </Button>
                
                <span className="px-4 py-2 text-sm text-muted-foreground">
                  Page {currentPage} of {totalPages}
                </span>
                
                <Button
                  variant="outline"
                  onClick={() => {
                    setCurrentPage(prev => Math.min(prev + 1, totalPages))
                  }}
                  disabled={currentPage === totalPages}
                >
                  Next
                </Button>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <BookOpen className="mx-auto h-12 w-12 text-muted-foreground" />
            <h3 className="mt-2 text-sm font-medium text-foreground">
              {searchQuery ? 'No borrowings found' : 'No borrowings yet'}
            </h3>
            <p className="mt-1 text-sm text-muted-foreground">
              {searchQuery
                ? 'Try adjusting your search terms'
                : isLibrarian()
                ? 'Borrowings will appear here when members borrow books'
                : 'Your borrowings will appear here when you borrow books'
              }
            </p>
          </div>
        )}
      </div>

      {/* Return Book Modal */}
      {showReturnModal && selectedBorrowing && (
        <DeleteConfirmModal
          title="Return Book"
          message={`Mark "${selectedBorrowing.book?.title || 'this book'}" as returned?`}
          confirmText="Return Book"
          onConfirm={handleReturnBook}
          onCancel={() => {
            setShowReturnModal(false)
            setSelectedBorrowing(null)
          }}
        />
      )}
    </MainLayout>
  )
}

const BorrowingCard = ({ borrowing, onReturn, isLibrarian }) => {
  const status = getBorrowingStatus(borrowing)
  const isOverdue = status === 'overdue'
  const isReturned = status === 'returned'
  const canReturn = isLibrarian && !isReturned

  const getDaysUntilDue = () => {
    if (isReturned) return null
    const today = new Date()
    const dueDate = new Date(borrowing.due_date)
    const diffTime = dueDate - today
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    return diffDays
  }

  const daysUntilDue = getDaysUntilDue()

  // Extract data from nested objects to avoid rendering complex objects
  const bookTitle = borrowing.book?.title || borrowing.book_title || 'Unknown Book'
  const bookAuthor = borrowing.book?.author || borrowing.book_author || 'Unknown Author'
  const userEmail = borrowing.user?.email || borrowing.user_email || 'Unknown User'

  return (
    <Card className={`${isOverdue ? 'border-destructive/50 bg-destructive/5' : ''}`}>
      <Card.Body className="p-6">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            {/* Book Info */}
            <div className="flex items-start space-x-4">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                  <BookOpen className="h-6 w-6 text-primary" />
                </div>
              </div>
              
              <div className="flex-1 min-w-0">
                <h3 className="text-lg font-medium text-foreground mb-1">
                  {bookTitle}
                </h3>
                <p className="text-sm text-muted-foreground mb-2">
                  by {bookAuthor}
                </p>
                
                {isLibrarian && (
                  <p className="text-sm text-muted-foreground mb-3">
                    Borrowed by: {userEmail}
                  </p>
                )}

                {/* Date Info */}
                <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                  <div className="flex items-center">
                    <Calendar className="h-4 w-4 mr-1" />
                    Borrowed: {formatDate(borrowing.borrowed_at)}
                  </div>
                  
                  <div className="flex items-center">
                    <Clock className="h-4 w-4 mr-1" />
                    Due: {formatDate(borrowing.due_date)}
                  </div>
                  
                  {isReturned && (
                    <div className="flex items-center">
                      <CheckCircle className="h-4 w-4 mr-1" />
                      Returned: {formatDate(borrowing.returned_at)}
                    </div>
                  )}
                </div>

                {/* Days until due */}
                {!isReturned && daysUntilDue !== null && (
                  <div className="mt-2">
                    <span className={`text-sm font-medium ${
                      isOverdue 
                        ? 'text-destructive' 
                        : daysUntilDue <= 3 
                        ? 'text-amber-600 dark:text-amber-400' 
                        : 'text-green-600 dark:text-green-400'
                    }`}>
                      {isOverdue 
                        ? `${Math.abs(daysUntilDue)} day${Math.abs(daysUntilDue) !== 1 ? 's' : ''} overdue`
                        : daysUntilDue === 0
                        ? 'Due today'
                        : `${daysUntilDue} day${daysUntilDue !== 1 ? 's' : ''} remaining`
                      }
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Status and Actions */}
          <div className="flex flex-col items-end space-y-3">
            {getStatusBadge(status)}
            
            {canReturn && (
              <Button
                size="sm"
                variant="outline"
                onClick={onReturn}
                className="flex items-center"
              >
                <RotateCcw className="h-4 w-4 mr-1" />
                Return Book
              </Button>
            )}
          </div>
        </div>
      </Card.Body>
    </Card>
  )
}

export default Borrowings 