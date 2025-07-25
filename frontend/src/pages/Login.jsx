import { useState } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff, Mail, Lock } from 'lucide-react'
import toast from 'react-hot-toast'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import Card from '@/components/ui/Card'
import useAuthStore from '@/store/authStore'
import { loginSchema } from '@/lib/validations'

const Login = () => {
  const [showPassword, setShowPassword] = useState(false)
  const navigate = useNavigate()
  const location = useLocation()
  const { login, isLoading } = useAuthStore()

  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  })

  // Redirect to intended page after login
  const from = location.state?.from?.pathname || '/dashboard'

  const onSubmit = async (data) => {
    try {
      const result = await login(data)
      
      if (result.success) {
        toast.success('Welcome back!')
        navigate(from, { replace: true })
      } else {
        // Handle specific error cases
        if (result.error.includes('email')) {
          setError('email', { message: result.error })
        } else if (result.error.includes('password')) {
          setError('password', { message: result.error })
        } else {
          setError('root', { message: result.error })
        }
      }
    } catch (error) {
      setError('root', { message: 'An unexpected error occurred. Please try again.' })
    }
  }

  return (
    <AuthLayout
      title="Welcome back"
      subtitle="Sign in to your account to continue"
    >
      <Card>
        <Card.Body>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* Email field */}
            <Input
              {...register('email')}
              id="email"
              type="email"
              label="Email address"
              placeholder="Enter your email"
              required
              error={errors.email?.message}
              leftIcon={Mail}
            />

            {/* Password field */}
            <Input
              {...register('password')}
              id="password"
              type={showPassword ? 'text' : 'password'}
              label="Password"
              placeholder="Enter your password"
              required
              error={errors.password?.message}
              leftIcon={Lock}
              rightIcon={showPassword ? EyeOff : Eye}
              onRightIconClick={() => setShowPassword(!showPassword)}
            />

            {/* General error message */}
            {errors.root && (
              <div className="rounded-md bg-red-50 p-4 border border-red-200">
                <p className="text-sm text-red-600">{errors.root.message}</p>
              </div>
            )}

            {/* Remember me and forgot password */}
            <div className="flex items-center justify-between">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <span className="ml-2 text-sm text-gray-600 dark:text-gray-400">
                  Remember me
                </span>
              </label>
              
              <Link
                to="/forgot-password"
                className="text-sm text-blue-600 hover:text-blue-500 font-medium"
              >
                Forgot your password?
              </Link>
            </div>

            {/* Submit button */}
            <Button
              type="submit"
              loading={isLoading}
              className="w-full"
            >
              Sign in
            </Button>

            {/* Sign up link */}
            <div className="text-center">
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Don't have an account?{' '}
                <Link
                  to="/register"
                  className="font-medium text-blue-600 hover:text-blue-500"
                >
                  Sign up
                </Link>
              </p>
            </div>
          </form>
        </Card.Body>
      </Card>

      {/* Demo credentials */}
      <Card className="mt-6">
        <Card.Body className="!py-4">
          <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-3">
            Demo Credentials
          </h3>
          <div className="space-y-2 text-xs text-gray-600 dark:text-gray-400">
            <div className="flex justify-between items-center">
              <span><strong>Librarian:</strong> librarian@library.com</span>
              <span><strong>Password:</strong> password123</span>
            </div>
            <div className="flex justify-between items-center">
              <span><strong>Member:</strong> member@library.com</span>
              <span><strong>Password:</strong> password123</span>
            </div>
          </div>
        </Card.Body>
      </Card>
    </AuthLayout>
  )
}

export default Login 