import { Menu, User } from 'lucide-react'
import useAuthStore from '@/store/authStore'

const TopBar = ({ onMenuClick, pageTitle, sidebarOpen = false }) => {
  const { user } = useAuthStore()

  return (
    <header className="sticky top-0 z-30 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b border-border">
      <div className="px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex items-center justify-between">
          {/* Mobile Menu Button & Page Title */}
          <div className="flex items-center gap-4">
            {!sidebarOpen && (
              <button
                className="p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-muted"
                onClick={onMenuClick}
              >
                <Menu className="w-5 h-5" />
              </button>
            )}
            
            {/* Page Title */}
            <div>
              <h1 className="text-xl font-bold text-foreground lg:text-2xl">
                {pageTitle || 'Library'}
              </h1>
              <p className="text-sm text-muted-foreground lg:hidden">
                Management System
              </p>
            </div>
          </div>

          {/* User Info & Quick Actions */}
          <div className="flex items-center gap-3">
            {/* User Badge for Desktop */}
            <div className="hidden lg:flex items-center gap-2 px-3 py-2 bg-muted/50 rounded-lg">
              <div className="w-6 h-6 bg-primary/10 rounded-md flex items-center justify-center">
                <User className="w-3 h-3 text-primary" />
              </div>
              <span className="text-xs font-medium text-muted-foreground">
                {user?.email?.split('@')[0] || 'User'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </header>
  )
}

export default TopBar 