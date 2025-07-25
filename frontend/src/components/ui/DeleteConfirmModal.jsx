import { AlertTriangle, X } from 'lucide-react'
import Button from './Button'
import Card from './Card'

const DeleteConfirmModal = ({ 
  title = "Confirm Delete", 
  message = "Are you sure you want to delete this item?", 
  onConfirm, 
  onCancel,
  confirmText = "Delete",
  cancelText = "Cancel",
  loading = false 
}) => {
  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onCancel} />
        
        <div className="relative w-full max-w-md">
          <Card>
            <Card.Header>
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">{title}</h3>
                <button
                  onClick={onCancel}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>
            </Card.Header>

            <Card.Body>
              <div className="space-y-4">
                {/* Warning Icon */}
                <div className="flex items-center justify-center">
                  <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                    <AlertTriangle className="h-6 w-6 text-red-600" />
                  </div>
                </div>

                {/* Message */}
                <div className="text-center">
                  <p className="text-gray-700">{message}</p>
                </div>

                {/* Actions */}
                <div className="flex space-x-3 pt-4">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={onCancel}
                    className="flex-1"
                    disabled={loading}
                  >
                    {cancelText}
                  </Button>
                  <Button
                    variant="danger"
                    onClick={onConfirm}
                    loading={loading}
                    className="flex-1"
                  >
                    {confirmText}
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

export default DeleteConfirmModal 