import { useState } from 'react'
import { X, Calendar, AlertTriangle } from 'lucide-react'
import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'

const BorrowBookModal = ({ book, onClose, onBorrow }) => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  // Calculate due date (2 weeks from today)
  const today = new Date()
  const dueDate = new Date(today)
  dueDate.setDate(today.getDate() + 14)

  const handleBorrow = async () => {
    try {
      setLoading(true)
      setError(null)
      
      await onBorrow({
        due_date: dueDate.toISOString().split('T')[0]
      })
      
      // If we reach here, the borrowing was successful
      // The parent component will handle closing the modal and showing the toast
      
    } catch (error) {
      console.error('Error borrowing book:', error)
      setError(
        error.response?.data?.message || 
        error.response?.data?.details || 
        error.response?.data?.errors?.[0] || 
        'Failed to borrow book. Please try again.'
      )
      setLoading(false) // Only set loading to false on error
    }
    // Note: We don't set loading to false on success because the modal will be closed
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
        
        <div className="relative w-full max-w-md">
          <Card>
            <Card.Header>
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">Borrow Book</h3>
                <button
                  onClick={onClose}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>
            </Card.Header>

            <Card.Body>
              <div className="space-y-4">
                {/* Book Information */}
                <div className="p-4 bg-blue-50 rounded-lg">
                  <h4 className="font-medium text-gray-900 mb-1">{book.title}</h4>
                  <p className="text-sm text-gray-600">by {book.author}</p>
                  <p className="text-xs text-gray-500 mt-1">{book.genre}</p>
                </div>

                {/* Borrowing Details */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center">
                      <Calendar className="h-4 w-4 text-gray-400 mr-2" />
                      <span className="text-sm font-medium text-gray-700">Due Date</span>
                    </div>
                    <span className="text-sm text-gray-900">
                      {dueDate.toLocaleDateString()}
                    </span>
                  </div>

                  <div className="flex items-start p-3 bg-yellow-50 rounded-lg">
                    <AlertTriangle className="h-4 w-4 text-yellow-600 mr-2 mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-yellow-800">
                      <p className="font-medium mb-1">Important</p>
                      <ul className="space-y-1 text-xs">
                        <li>• You have 14 days to return this book</li>
                        <li>• Late returns may result in fines</li>
                        <li>• You cannot borrow the same book multiple times</li>
                        <li>• Please keep the book in good condition</li>
                      </ul>
                    </div>
                  </div>
                </div>

                {/* Error Message */}
                {error && (
                  <div className="p-3 text-sm text-red-600 bg-red-50 rounded-lg">
                    {error}
                  </div>
                )}

                {/* Actions */}
                <div className="flex space-x-3 pt-4">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={onClose}
                    className="flex-1"
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={handleBorrow}
                    loading={loading}
                    className="flex-1"
                  >
                    Confirm Borrowing
                  </Button>
                </div>
              </div>
            </Card.Body>
          </Card>
        </div>
      </div>
    </div>
  )
}

export default BorrowBookModal 