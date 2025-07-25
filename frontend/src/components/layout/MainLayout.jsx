import { useState, useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'
import TopBar from './TopBar'

const MainLayout = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const location = useLocation()

  // Initialize sidebar state based on screen size
  useEffect(() => {
    const handleResize = () => {
      // Open by default on large screens, closed on mobile
      setSidebarOpen(window.innerWidth >= 1024) // lg breakpoint
    }
    
    // Set initial state
    handleResize()
    
    // Listen for window resize
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  // Navigation items for page title detection
  const navigation = [
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Books', href: '/books' },
    { name: 'Borrowings', href: '/borrowings' },
    { name: 'Users', href: '/users' },
  ]

  const getPageTitle = () => {
    const currentItem = navigation.find(item => 
      location.pathname === item.href || location.pathname.startsWith(item.href + '/')
    )
    return currentItem?.name || 'Library'
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Sidebar */}
      <Sidebar 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)} 
      />

      {/* Main Content Area */}
      <div className={`${sidebarOpen ? 'lg:pl-72' : 'pl-0'}`}>
        {/* Top Navigation Bar */}
        <TopBar 
          onMenuClick={() => setSidebarOpen(true)}
          pageTitle={getPageTitle()}
          sidebarOpen={sidebarOpen}
        />

        {/* Page Content */}
        <main className="px-4 sm:px-6 lg:px-8 py-6 lg:py-8">
          <div className="max-w-none mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}

export default MainLayout 