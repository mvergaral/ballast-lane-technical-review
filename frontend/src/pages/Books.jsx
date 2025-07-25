import { useState, useEffect } from 'react'
import { Plus, Search, Book, Edit, Trash2, Eye, Users, BookOpen } from 'lucide-react'
import toast from 'react-hot-toast'
import MainLayout from '@/components/layout/MainLayout'
import Card from '@/components/ui/Card'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import useAuthStore from '@/store/authStore'
import { booksAPI, borrowingsAPI } from '@/lib/api'
import useDashboardRefresh from '@/hooks/useDashboardRefresh'
import BookModal from '@/components/books/BookModal'
import BookDetailsModal from '@/components/books/BookDetailsModal'
import BorrowBookModal from '@/components/books/BorrowBookModal'
import DeleteConfirmModal from '@/components/ui/DeleteConfirmModal'

const Books = () => {
  const { isLibrarian } = useAuthStore()
  const { invalidateDashboard } = useDashboardRefresh()
  const [books, setBooks] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [searchTimeout, setSearchTimeout] = useState(null)
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [selectedBook, setSelectedBook] = useState(null)
  const [modalType, setModalType] = useState(null) // 'create', 'edit', 'view', 'borrow', 'delete'

  useEffect(() => {
    fetchBooks()
  }, [currentPage])

  useEffect(() => {
    // Debounced search
    if (searchTimeout) {
      clearTimeout(searchTimeout)
    }
    
    const timeout = setTimeout(() => {
      if (searchQuery.trim()) {
        handleSearch(searchQuery)
      } else {
        fetchBooks()
      }
    }, 500)
    
    setSearchTimeout(timeout)
    
    return () => clearTimeout(timeout)
  }, [searchQuery])

  const fetchBooks = async (page = 1) => {
    try {
      setLoading(true)
      const response = await booksAPI.getAll({ page, per_page: 12 })
      const { books: booksData, pagination } = response.data
      
      setBooks(booksData || [])
      setCurrentPage(pagination?.current_page || 1)
      setTotalPages(pagination?.total_pages || 1)
    } catch (error) {
      console.error('Error fetching books:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = async (query) => {
    try {
      setLoading(true)
      const response = await booksAPI.search(query, { page: 1, per_page: 12 })
      const { books: booksData, pagination } = response.data
      
      setBooks(booksData || [])
      setCurrentPage(pagination?.current_page || 1)
      setTotalPages(pagination?.total_pages || 1)
    } catch (error) {
      console.error('Error searching books:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleBookSaved = () => {
    setModalType(null)
    setSelectedBook(null)
    fetchBooks(currentPage)
    
    // Invalidate dashboard to update book statistics
    invalidateDashboard()
  }

  const handleBookDeleted = async () => {
    try {
      await booksAPI.delete(selectedBook.id)
      setModalType(null)
      setSelectedBook(null)
      fetchBooks(currentPage)
      
      // Invalidate dashboard to update book statistics
      invalidateDashboard()
      
      // Show success toast
      toast.success(`Successfully deleted "${selectedBook.title}"!`, {
        duration: 3000,
        position: 'top-center',
        icon: '🗑️',
      })
    } catch (error) {
      console.error('Error deleting book:', error)
      
      // Show error toast
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.errors?.[0] || 
                          'Failed to delete book'
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-center',
      })
    }
  }

  const handleBorrowBook = async (borrowingData) => {
    try {
      await borrowingsAPI.create({ book_id: selectedBook.id, ...borrowingData })
      setModalType(null)
      setSelectedBook(null)
      fetchBooks(currentPage)
      
      // Invalidate dashboard to update statistics
      invalidateDashboard()
      
      // Show success toast
      toast.success(`Successfully borrowed "${selectedBook.title}"!`, {
        duration: 4000,
        position: 'top-center',
        icon: '📚',
      })
    } catch (error) {
      console.error('Error borrowing book:', error)
      
      // Show error toast
      const errorMessage = error.response?.data?.message || 
                          error.response?.data?.errors?.[0] || 
                          'Failed to borrow book'
      toast.error(errorMessage, {
        duration: 4000,
        position: 'top-center',
      })
      
      throw error
    }
  }

  const openModal = (type, book = null) => {
    setModalType(type)
    setSelectedBook(book)
  }

  const closeModal = () => {
    setModalType(null)
    setSelectedBook(null)
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Books</h1>
            <p className="text-gray-600">
              {isLibrarian() ? 'Manage your library collection' : 'Browse available books'}
            </p>
          </div>
          
          {isLibrarian() && (
            <Button
              onClick={() => openModal('create')}
              className="inline-flex items-center"
            >
              <Plus className="mr-2 h-4 w-4" />
              Add Book
            </Button>
          )}
        </div>

        {/* Search */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <Input
              type="text"
              placeholder="Search books by title, author, or genre..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              leftIcon={Search}
            />
          </div>
        </div>

        {/* Books Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full spin"></div>
            <p className="ml-3 text-sm text-muted-foreground">Loading books...</p>
          </div>
        ) : books.length > 0 ? (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {books.map((book) => (
                <BookCard
                  key={book.id}
                  book={book}
                  onView={() => openModal('view', book)}
                  onEdit={() => openModal('edit', book)}
                  onDelete={() => openModal('delete', book)}
                  onBorrow={() => openModal('borrow', book)}
                  isLibrarian={isLibrarian()}
                />
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
            <Book className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">
              {searchQuery ? 'No books found' : 'No books yet'}
            </h3>
            <p className="mt-1 text-sm text-gray-500">
              {searchQuery
                ? 'Try adjusting your search terms'
                : isLibrarian()
                ? 'Get started by adding your first book'
                : 'Books will appear here once they are added'
              }
            </p>
          </div>
        )}
      </div>

      {/* Modals */}
      {modalType === 'create' && (
        <BookModal
          onClose={closeModal}
          onSaved={handleBookSaved}
        />
      )}

      {modalType === 'edit' && selectedBook && (
        <BookModal
          book={selectedBook}
          onClose={closeModal}
          onSaved={handleBookSaved}
        />
      )}

      {modalType === 'view' && selectedBook && (
        <BookDetailsModal
          book={selectedBook}
          onClose={closeModal}
          onEdit={() => {
            closeModal()
            openModal('edit', selectedBook)
          }}
          onDelete={() => {
            closeModal()
            openModal('delete', selectedBook)
          }}
          onBorrow={() => {
            closeModal()
            openModal('borrow', selectedBook)
          }}
          isLibrarian={isLibrarian()}
        />
      )}

      {modalType === 'borrow' && selectedBook && (
        <BorrowBookModal
          book={selectedBook}
          onClose={closeModal}
          onBorrow={handleBorrowBook}
        />
      )}

      {modalType === 'delete' && selectedBook && (
        <DeleteConfirmModal
          title="Delete Book"
          message={`Are you sure you want to delete "${selectedBook.title}"? This action cannot be undone.`}
          onConfirm={handleBookDeleted}
          onCancel={closeModal}
        />
      )}
    </MainLayout>
  )
}

const BookCard = ({ book, onView, onEdit, onDelete, onBorrow, isLibrarian }) => {
  const isAvailable = book.available_copies > 0

  return (
    <Card className="h-full flex flex-col">
      <Card.Body className="flex-1 p-4">
        <div className="flex flex-col h-full">
          {/* Book Info */}
          <div className="flex-1">
            <h3 className="font-semibold text-gray-900 mb-1 line-clamp-2">
              {book.title}
            </h3>
            <p className="text-sm text-gray-600 mb-2">by {book.author}</p>
            <p className="text-xs text-gray-500 mb-3">{book.genre}</p>
            
            <div className="space-y-1 text-xs text-gray-500">
              <p>ISBN: {book.isbn}</p>
              <p>Total copies: {book.total_copies}</p>
              <p className={`font-medium ${isAvailable ? 'text-green-600' : 'text-red-600'}`}>
                Available: {book.available_copies}
              </p>
            </div>
          </div>

          {/* Actions */}
          <div className="flex flex-wrap gap-2 mt-4">
            <Button
              size="sm"
              variant="outline"
              onClick={onView}
              className="flex-1"
            >
              <Eye className="mr-1 h-3 w-3" />
              View
            </Button>
            
            {isLibrarian ? (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={onEdit}
                  className="flex-1"
                >
                  <Edit className="mr-1 h-3 w-3" />
                  Edit
                </Button>
                <Button
                  size="sm"
                  variant="danger"
                  onClick={onDelete}
                  className="flex-1"
                >
                  <Trash2 className="mr-1 h-3 w-3" />
                  Delete
                </Button>
              </>
            ) : (
              <Button
                size="sm"
                variant={isAvailable ? "primary" : "outline"}
                onClick={onBorrow}
                disabled={!isAvailable}
                className="flex-1"
              >
                <Book className="mr-1 h-3 w-3" />
                {isAvailable ? 'Borrow' : 'Unavailable'}
              </Button>
            )}
          </div>
        </div>
      </Card.Body>
    </Card>
  )
}

export default Books 