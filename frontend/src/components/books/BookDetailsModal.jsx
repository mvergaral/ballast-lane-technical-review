import { X, Edit, Trash2, Book } from 'lucide-react'
import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'

const BookDetailsModal = ({ book, onClose, onEdit, onDelete, onBorrow, isLibrarian }) => {
  const isAvailable = book.available_copies > 0

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
        
        <div className="relative w-full max-w-lg">
          <Card>
            <Card.Header>
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">Book Details</h3>
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
                <div className="grid grid-cols-1 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Title
                    </label>
                    <p className="text-gray-900">{book.title}</p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Author
                    </label>
                    <p className="text-gray-900">{book.author}</p>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Genre
                      </label>
                      <p className="text-gray-900">{book.genre}</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        ISBN
                      </label>
                      <p className="text-gray-900 text-sm">{book.isbn}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Total Copies
                      </label>
                      <p className="text-gray-900">{book.total_copies}</p>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Available Copies
                      </label>
                      <p className={`font-medium ${isAvailable ? 'text-green-600' : 'text-red-600'}`}>
                        {book.available_copies}
                      </p>
                    </div>
                  </div>

                  {/* Availability Status */}
                  <div className="p-3 rounded-lg bg-gray-50">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-gray-700">Status</span>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        isAvailable 
                          ? 'text-green-700 bg-green-100' 
                          : 'text-red-700 bg-red-100'
                      }`}>
                        {isAvailable ? 'Available' : 'Not Available'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col sm:flex-row gap-3 pt-4">
                  {isLibrarian ? (
                    <>
                      <Button
                        variant="outline"
                        onClick={onEdit}
                        className="flex-1"
                      >
                        <Edit className="mr-2 h-4 w-4" />
                        Edit Book
                      </Button>
                      <Button
                        variant="danger"
                        onClick={onDelete}
                        className="flex-1"
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Delete Book
                      </Button>
                    </>
                  ) : (
                    <Button
                      variant={isAvailable ? "primary" : "outline"}
                      onClick={onBorrow}
                      disabled={!isAvailable}
                      className="flex-1"
                    >
                      <Book className="mr-2 h-4 w-4" />
                      {isAvailable ? 'Borrow Book' : 'Not Available'}
                    </Button>
                  )}
                </div>
              </div>
            </Card.Body>
          </Card>
        </div>
      </div>
    </div>
  )
}

export default BookDetailsModal 