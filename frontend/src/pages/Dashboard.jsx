import { useState, useEffect } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Book, Users, Clock, AlertTriangle, BookOpen, Calendar, RefreshCw } from 'lucide-react'
import toast from 'react-hot-toast'
import MainLayout from '@/components/layout/MainLayout'
import Card from '@/components/ui/Card'
import Button from '@/components/ui/Button'
import useAuthStore from '@/store/authStore'
import { dashboardAPI } from '@/lib/api'
import { formatDate } from '@/lib/utils'

const Dashboard = () => {
  const { user, isLibrarian } = useAuthStore()
  const queryClient = useQueryClient()

  // Use React Query for dashboard stats
  const {
    data: stats,
    isLoading: loading,
    error,
    refetch,
    isRefetching
  } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => dashboardAPI.getStats().then(res => res.data),
    staleTime: 30 * 1000, // Consider data fresh for 30 seconds
    refetchOnWindowFocus: true, // Refetch when user returns to tab
    refetchInterval: 60 * 1000, // Auto refetch every minute
  })

  const handleRefresh = async () => {
    try {
      await refetch()
      toast.success('Dashboard refreshed!', {
        duration: 2000,
        position: 'top-center',
        icon: '🔄',
      })
    } catch (error) {
      toast.error('Failed to refresh dashboard', {
        duration: 3000,
        position: 'top-center',
      })
    }
  }

  const getTimeOfDayGreeting = () => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 18) return 'Good afternoon'
    return 'Good evening'
  }

  if (loading) {
    return (
      <MainLayout>
        <div className="min-h-[400px] flex items-center justify-center">
          <div className="text-center space-y-4">
            <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full"></div>
            <p className="text-sm text-muted-foreground">Loading dashboard...</p>
          </div>
        </div>
      </MainLayout>
    )
  }

  if (error) {
    return (
      <MainLayout>
        <div className="min-h-[400px] flex items-center justify-center">
          <div className="text-center space-y-4 max-w-md">
            <div className="w-12 h-12 bg-destructive/10 rounded-full flex items-center justify-center mx-auto">
              <AlertTriangle className="w-6 h-6 text-destructive" />
            </div>
            <div className="space-y-2">
              <h3 className="font-semibold text-foreground">Failed to load</h3>
              <p className="text-sm text-muted-foreground">
                {error?.response?.data?.message || error?.message || 'Failed to load dashboard statistics'}
              </p>
            </div>
            <Button onClick={handleRefresh} variant="outline" size="sm" loading={isRefetching}>
              <RefreshCw className="w-4 h-4 mr-2" />
              Try again
            </Button>
          </div>
        </div>
      </MainLayout>
    )
  }

  return (
    <MainLayout>
      <div className="space-y-8">
        {/* Header Section */}
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <h1 className="text-3xl font-bold tracking-tight text-foreground">
              {getTimeOfDayGreeting()}, {user?.email?.split('@')[0]}
            </h1>
            <p className="text-muted-foreground">
              {isLibrarian() 
                ? 'Library management overview' 
                : 'Your library activity'
              }
            </p>
          </div>
          
          {/* Refresh Button */}
          <Button 
            onClick={handleRefresh} 
            variant="outline" 
            size="sm" 
            loading={isRefetching}
            className="flex items-center gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </Button>
        </div>

        {/* Dashboard Content */}
        {isLibrarian() ? (
          <LibrarianDashboard stats={stats} />
        ) : (
          <MemberDashboard stats={stats} />
        )}
      </div>
    </MainLayout>
  )
}

const LibrarianDashboard = ({ stats }) => {
  const statsData = [
    {
      title: 'Total Books',
      value: stats.total_books || 0,
      icon: Book,
      description: 'in the library',
      trend: null,
      color: 'blue'
    },
    {
      title: 'Books Borrowed',
      value: stats.total_borrowed_books || 0,
      icon: BookOpen,
      description: 'currently borrowed',
      trend: null,
      color: 'green'
    },
    {
      title: 'Due Today',
      value: stats.books_due_today || 0,
      icon: Calendar,
      description: 'books due today',
      trend: null,
      color: 'amber'
    },
    {
      title: 'Overdue',
      value: stats.overdue_books || 0,
      icon: AlertTriangle,
      description: 'books overdue',
      trend: null,
      color: 'red'
    }
  ]

  return (
    <div className="space-y-8">
      {/* Key Metrics */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-4">Key Metrics</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          {statsData.map((stat) => (
            <MetricCard key={stat.title} {...stat} />
          ))}
        </div>
      </section>

      {/* Detailed Sections */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Overdue Members */}
        <section>
          <Card className="h-full">
            <Card.Header className="pb-3">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-foreground">Members with Overdue Books</h3>
                {stats.overdue_members?.length > 0 && (
                  <span className="text-xs text-muted-foreground">
                    {stats.overdue_members.length} total
                  </span>
                )}
              </div>
            </Card.Header>
            <Card.Body className="pt-0">
              {stats.overdue_members && stats.overdue_members.length > 0 ? (
                <div className="space-y-3">
                  {stats.overdue_members.slice(0, 5).map((member) => (
                    <div key={member.id} className="flex items-center justify-between p-3 bg-red-50 dark:bg-red-950/20 rounded-lg border border-red-100 dark:border-red-900/50">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-foreground truncate">{member.email}</p>
                        <p className="text-sm text-muted-foreground">
                          {member.overdue_count} book{member.overdue_count !== 1 ? 's' : ''} overdue
                        </p>
                      </div>
                      <span className="px-2 py-1 text-xs font-medium text-red-700 dark:text-red-400 bg-red-100 dark:bg-red-900/40 rounded-md whitespace-nowrap">
                        Overdue
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState 
                  icon={Users} 
                  title="No overdue books"
                  description="All loans are up to date"
                />
              )}
            </Card.Body>
          </Card>
        </section>

        {/* Recent Borrowings */}
        <section>
          <Card className="h-full">
            <Card.Header className="pb-3">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-foreground">Recent Borrowings</h3>
                {stats.recent_borrowings?.length > 0 && (
                  <span className="text-xs text-muted-foreground">
                    Latest {Math.min(5, stats.recent_borrowings.length)}
                  </span>
                )}
              </div>
            </Card.Header>
            <Card.Body className="pt-0">
              {stats.recent_borrowings && stats.recent_borrowings.length > 0 ? (
                <div className="space-y-3">
                  {stats.recent_borrowings.slice(0, 5).map((borrowing) => (
                    <div key={borrowing.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-foreground truncate">{borrowing.book_title}</p>
                        <p className="text-sm text-muted-foreground truncate">by {borrowing.user_email}</p>
                      </div>
                      <span className="text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(borrowing.borrowed_at)}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState 
                  icon={BookOpen} 
                  title="No recent borrowings"
                  description="No borrowing activity"
                />
              )}
            </Card.Body>
          </Card>
        </section>
      </div>
    </div>
  )
}

const MemberDashboard = ({ stats }) => {
  const statsData = [
    {
      title: 'Books Borrowed',
      value: stats.stats.my_borrowed_books || 0,
      icon: BookOpen,
      description: 'currently borrowed',
      color: 'blue'
    },
    {
      title: 'Due Soon',
      value: stats.stats.my_books_due_soon || 0,
      icon: Clock,
      description: 'due this week',
      color: 'amber'
    },
    {
      title: 'Overdue',
      value: stats.stats.my_overdue_books || 0,
      icon: AlertTriangle,
      description: 'books overdue',
      color: 'red'
    }
  ]

  return (
    <div className="space-y-8">
      {/* Member Metrics */}
      <section>
        <h2 className="text-lg font-semibold text-foreground mb-4">My Activity</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {statsData.map((stat) => (
            <MetricCard key={stat.title} {...stat} />
          ))}
        </div>
      </section>

      {/* Member Details */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Current Borrowings */}
        <section>
          <Card className="h-full">
            <Card.Header className="pb-3">
              <h3 className="font-semibold text-foreground">My Current Borrowings</h3>
            </Card.Header>
            <Card.Body className="pt-0">
              {stats.my_borrowings && stats.my_borrowings.length > 0 ? (
                <div className="space-y-3">
                  {stats.my_borrowings.map((borrowing) => (
                    <div key={borrowing.id} className="p-4 border border-border rounded-lg space-y-2">
                      <div className="flex items-start justify-between">
                        <div className="min-w-0 flex-1">
                          <p className="font-medium text-foreground">{borrowing.book_title}</p>
                          <p className="text-sm text-muted-foreground">by {borrowing.book_author}</p>
                        </div>
                        <StatusBadge borrowing={borrowing} />
                      </div>
                      <p className="text-xs text-muted-foreground">
                        Due: {formatDate(borrowing.due_date)}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState 
                  icon={BookOpen} 
                  title="No current borrowings"
                  description="You have no borrowed books"
                />
              )}
            </Card.Body>
          </Card>
        </section>

        {/* Borrowing History */}
        <section>
          <Card className="h-full">
            <Card.Header className="pb-3">
              <h3 className="font-semibold text-foreground">Recent History</h3>
            </Card.Header>
            <Card.Body className="pt-0">
              {stats.my_borrowing_history && stats.my_borrowing_history.length > 0 ? (
                <div className="space-y-3">
                  {stats.my_borrowing_history.slice(0, 5).map((borrowing) => (
                    <div key={borrowing.id} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                      <div className="min-w-0 flex-1">
                        <p className="font-medium text-foreground truncate">{borrowing.book_title}</p>
                        <p className="text-sm text-muted-foreground truncate">by {borrowing.book_author}</p>
                      </div>
                      <div className="text-right space-y-1">
                        <span className="px-2 py-1 text-xs font-medium text-green-700 dark:text-green-400 bg-green-100 dark:bg-green-900/40 rounded-md">
                          Returned
                        </span>
                        <p className="text-xs text-muted-foreground">
                          {formatDate(borrowing.returned_at)}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState 
                  icon={Book} 
                  title="No history"
                  description="No previous borrowings"
                />
              )}
            </Card.Body>
          </Card>
        </section>
      </div>
    </div>
  )
}

const MetricCard = ({ title, value, icon: Icon, description, color = 'blue' }) => {
  const colorStyles = {
    blue: 'text-blue-600 bg-blue-50 dark:text-blue-400 dark:bg-blue-950/20',
    green: 'text-green-600 bg-green-50 dark:text-green-400 dark:bg-green-950/20',
    amber: 'text-amber-600 bg-amber-50 dark:text-amber-400 dark:bg-amber-950/20',
    red: 'text-red-600 bg-red-50 dark:text-red-400 dark:bg-red-950/20'
  }

  return (
    <Card>
      <Card.Body className="p-6">
        <div className="flex items-center gap-4">
          <div className={`p-2 rounded-lg ${colorStyles[color]}`}>
            <Icon className="w-5 h-5" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-2xl font-bold text-foreground">{value}</p>
            <p className="text-sm font-medium text-foreground">{title}</p>
            <p className="text-xs text-muted-foreground">{description}</p>
          </div>
        </div>
      </Card.Body>
    </Card>
  )
}

const StatusBadge = ({ borrowing }) => {
  if (borrowing.is_overdue) {
    return (
      <span className="px-2 py-1 text-xs font-medium text-red-700 dark:text-red-400 bg-red-100 dark:bg-red-900/40 rounded-md">
        Overdue
      </span>
    )
  }
  
  if (borrowing.is_due_soon) {
    return (
      <span className="px-2 py-1 text-xs font-medium text-amber-700 dark:text-amber-400 bg-amber-100 dark:bg-amber-900/40 rounded-md">
        Due Soon
      </span>
    )
  }
  
  return (
    <span className="px-2 py-1 text-xs font-medium text-green-700 dark:text-green-400 bg-green-100 dark:bg-green-900/40 rounded-md">
      Active
    </span>
  )
}

const EmptyState = ({ icon: Icon, title, description }) => (
  <div className="text-center py-8">
    <div className="w-12 h-12 bg-muted/50 rounded-full flex items-center justify-center mx-auto mb-3">
      <Icon className="w-6 h-6 text-muted-foreground" />
    </div>
    <h4 className="text-sm font-medium text-foreground mb-1">{title}</h4>
    <p className="text-xs text-muted-foreground">{description}</p>
  </div>
)

export default Dashboard 