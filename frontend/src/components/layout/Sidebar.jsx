import { Link, useLocation } from 'react-router-dom'
import { BookOpen, Home, Book, Users, FileText, LogOut, X, User } from 'lucide-react'
import useAuthStore from '@/store/authStore'
import Button from '@/components/ui/Button'

const Sidebar = ({ isOpen, onClose }) => {
  const { user, logout, isLibrarian } = useAuthStore()
  const location = useLocation()

  const handleLogout = async () => {
    await logout()
    window.location.href = '/login'
  }

  const navigation = [
    { 
      name: 'Dashboard', 
      href: '/dashboard', 
      icon: Home, 
      show: true,
      description: 'Overview & insights'
    },
    { 
      name: 'Books', 
      href: '/books', 
      icon: Book, 
      show: true,
      description: 'Book catalog'
    },
    { 
      name: 'Borrowings', 
      href: '/borrowings', 
      icon: FileText, 
      show: true,
      description: 'Loan management'
    },
    { 
      name: 'Users', 
      href: '/users', 
      icon: Users, 
      show: isLibrarian(),
      description: 'Member management'
    },
  ].filter(item => item.show)

  const isActive = (href) => location.pathname === href || location.pathname.startsWith(href + '/')

  return (
    <>
      {/* Mobile sidebar backdrop */}
      {isOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed inset-y-0 left-0 z-50 w-72 bg-card border-r border-border shadow-lg
        ${isOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex flex-col h-full">
          {/* Brand Header */}
          <div className="p-6 border-b border-border">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                  <BookOpen className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h1 className="text-lg font-bold text-foreground">Library</h1>
                  <p className="text-xs text-muted-foreground">Management System</p>
                </div>
              </div>
              <button
                className="p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted"
                onClick={onClose}
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* User Profile */}
          <div className="p-6 border-b border-border">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 bg-primary/10 rounded-xl flex items-center justify-center">
                <User className="w-6 h-6 text-primary" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-foreground truncate">
                  {user?.email?.split('@')[0] || 'User'}
                </p>
                <div className="flex items-center gap-2">
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium ${
                    user?.role === 'librarian' 
                      ? 'bg-blue-50 text-blue-700 dark:bg-blue-950/20 dark:text-blue-400'
                      : 'bg-green-50 text-green-700 dark:bg-green-950/20 dark:text-green-400'
                  }`}>
                    {user?.role === 'librarian' ? 'Librarian' : 'Member'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-6 space-y-2">
            <div className="mb-4">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Navigation
              </h2>
            </div>
            {navigation.map((item) => (
              <Link
                key={item.name}
                to={item.href}
                className={`
                  flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl
                  ${isActive(item.href)
                    ? 'bg-primary text-primary-foreground shadow-sm'
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
                  }
                `}
                onClick={onClose}
              >
                <item.icon className={`w-5 h-5 ${
                  isActive(item.href) ? 'text-primary-foreground' : 'text-muted-foreground'
                }`} />
                <div className="flex-1">
                  <div className={`font-medium ${isActive(item.href) ? 'text-primary-foreground' : ''}`}>
                    {item.name}
                  </div>
                  <div className={`text-xs ${
                    isActive(item.href) 
                      ? 'text-primary-foreground/70' 
                      : 'text-muted-foreground/60'
                  }`}>
                    {item.description}
                  </div>
                </div>
                {isActive(item.href) && (
                  <div className="w-1 h-6 bg-primary-foreground/30 rounded-full" />
                )}
              </Link>
            ))}
          </nav>

          {/* Logout Section */}
          <div className="p-6 border-t border-border">
            <Button
              variant="outline"
              size="sm"
              className="w-full justify-start gap-3 text-muted-foreground hover:text-foreground"
              onClick={handleLogout}
            >
              <LogOut className="w-4 h-4" />
              <span>Sign Out</span>
            </Button>
          </div>
        </div>
      </aside>
    </>
  )
}

export default Sidebar 