import { useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'

export const useDashboardRefresh = () => {
  const queryClient = useQueryClient()

  const invalidateDashboard = async (showToast = false) => {
    try {
      // Invalidate dashboard query to trigger refetch
      await queryClient.invalidateQueries({
        queryKey: ['dashboard'],
        refetchType: 'active', // Only refetch if dashboard is currently mounted
      })

      if (showToast) {
        toast.success('Dashboard updated!', {
          duration: 2000,
          position: 'top-center',
          icon: '📊',
        })
      }
    } catch (error) {
      console.error('Failed to invalidate dashboard:', error)
      if (showToast) {
        toast.error('Failed to update dashboard', {
          duration: 2000,
          position: 'top-center',
        })
      }
    }
  }

  const refreshDashboard = async () => {
    try {
      // Force refetch dashboard data
      await queryClient.refetchQueries({
        queryKey: ['dashboard'],
        type: 'active',
      })
    } catch (error) {
      console.error('Failed to refresh dashboard:', error)
    }
  }

  return {
    invalidateDashboard,
    refreshDashboard,
  }
}

export default useDashboardRefresh 