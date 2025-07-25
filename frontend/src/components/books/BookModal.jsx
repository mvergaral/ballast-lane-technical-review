import { useState, useEffect } from 'react'
import { X } from 'lucide-react'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import Card from '@/components/ui/Card'
import { booksAPI } from '@/lib/api'

const BookModal = ({ book = null, onClose, onSaved }) => {
  const isEdit = !!book
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState({})
  const [formData, setFormData] = useState({
    title: '',
    author: '',
    genre: '',
    isbn: '',
    total_copies: 1,
  })

  useEffect(() => {
    if (book) {
      setFormData({
        title: book.title || '',
        author: book.author || '',
        genre: book.genre || '',
        isbn: book.isbn || '',
        total_copies: book.total_copies || 1,
      })
    }
  }, [book])

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: name === 'total_copies' ? parseInt(value) || 0 : value
    }))
    
    // Clear error for this field
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }))
    }
  }

  const validateForm = () => {
    const newErrors = {}
    
    if (!formData.title.trim()) {
      newErrors.title = 'Title is required'
    }
    
    if (!formData.author.trim()) {
      newErrors.author = 'Author is required'
    }
    
    if (!formData.genre.trim()) {
      newErrors.genre = 'Genre is required'
    }
    
    if (!formData.isbn.trim()) {
      newErrors.isbn = 'ISBN is required'
    }
    
    if (formData.total_copies < 1) {
      newErrors.total_copies = 'Total copies must be at least 1'
    }
    
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!validateForm()) {
      return
    }

    try {
      setLoading(true)
      
      if (isEdit) {
        await booksAPI.update(book.id, formData)
      } else {
        await booksAPI.create(formData)
      }
      
      onSaved()
    } catch (error) {
      console.error('Error saving book:', error)
      
      // Handle validation errors from API
      if (error.response?.data?.errors) {
        const apiErrors = {}
        error.response.data.errors.forEach(errorMsg => {
          // Parse error messages to match field names
          if (errorMsg.includes('Title')) apiErrors.title = errorMsg
          else if (errorMsg.includes('Author')) apiErrors.author = errorMsg
          else if (errorMsg.includes('Genre')) apiErrors.genre = errorMsg
          else if (errorMsg.includes('ISBN')) apiErrors.isbn = errorMsg
          else if (errorMsg.includes('Total copies')) apiErrors.total_copies = errorMsg
          else apiErrors.general = errorMsg
        })
        setErrors(apiErrors)
      } else {
        setErrors({ general: 'An error occurred while saving the book' })
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
        
        <div className="relative w-full max-w-md">
          <Card>
            <Card.Header>
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">
                  {isEdit ? 'Edit Book' : 'Add New Book'}
                </h3>
                <button
                  onClick={onClose}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>
            </Card.Header>

            <Card.Body>
              <form onSubmit={handleSubmit} className="space-y-4">
                {errors.general && (
                  <div className="p-3 text-sm text-red-600 bg-red-50 rounded-lg">
                    {errors.general}
                  </div>
                )}

                <Input
                  label="Title"
                  name="title"
                  value={formData.title}
                  onChange={handleChange}
                  error={errors.title}
                  required
                  placeholder="Enter book title"
                />

                <Input
                  label="Author"
                  name="author"
                  value={formData.author}
                  onChange={handleChange}
                  error={errors.author}
                  required
                  placeholder="Enter author name"
                />

                <Input
                  label="Genre"
                  name="genre"
                  value={formData.genre}
                  onChange={handleChange}
                  error={errors.genre}
                  required
                  placeholder="Enter book genre"
                />

                <Input
                  label="ISBN"
                  name="isbn"
                  value={formData.isbn}
                  onChange={handleChange}
                  error={errors.isbn}
                  required
                  placeholder="Enter ISBN"
                />

                <Input
                  label="Total Copies"
                  name="total_copies"
                  type="number"
                  min="1"
                  value={formData.total_copies}
                  onChange={handleChange}
                  error={errors.total_copies}
                  required
                />

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
                    type="submit"
                    loading={loading}
                    className="flex-1"
                  >
                    {isEdit ? 'Update' : 'Create'} Book
                  </Button>
                </div>
              </form>
            </Card.Body>
          </Card>
        </div>
      </div>
    </div>
  )
}

export default BookModal 