import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff, Mail, Lock, UserPlus, Check } from 'lucide-react'
import toast from 'react-hot-toast'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import Card from '@/components/ui/Card'
import useAuthStore from '@/store/authStore'
import { registerSchema } from '@/lib/validations'

const Register = () => {
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [acceptTerms, setAcceptTerms] = useState(false)
  const navigate = useNavigate()
  const { register: registerUser, isLoading } = useAuthStore()

  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
    watch,
  } = useForm({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      email: '',
      password: '',
      password_confirmation: '',
    },
  })

  const password = watch('password')

  // Password strength validation
  const getPasswordStrength = (password) => {
    if (!password) return { strength: 0, text: '', color: '' }
    
    let strength = 0
    const checks = {
      length: password.length >= 6,
      lowercase: /[a-z]/.test(password),
      uppercase: /[A-Z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password),
    }
    
    strength = Object.values(checks).filter(Boolean).length
    
    if (strength < 2) return { strength, text: 'Weak', color: 'text-red-500' }
    if (strength < 4) return { strength, text: 'Fair', color: 'text-yellow-500' }
    if (strength < 5) return { strength, text: 'Good', color: 'text-blue-500' }
    return { strength, text: 'Strong', color: 'text-green-500' }
  }

  const passwordStrength = getPasswordStrength(password)

  const onSubmit = async (data) => {
    if (!acceptTerms) {
      setError('root', { message: 'You must accept the terms and conditions to continue.' })
      return
    }

    try {
      const result = await registerUser(data)
      
      if (result.success) {
        toast.success('Account created successfully! Welcome to the Library System.')
        navigate('/dashboard', { replace: true })
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
      title="Create your account"
      subtitle="Join our library management system"
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
              placeholder="Enter your email address"
              required
              error={errors.email?.message}
              leftIcon={Mail}
            />

            {/* Password field */}
            <div>
              <Input
                {...register('password')}
                id="password"
                type={showPassword ? 'text' : 'password'}
                label="Password"
                placeholder="Create a strong password"
                required
                error={errors.password?.message}
                leftIcon={Lock}
                rightIcon={showPassword ? EyeOff : Eye}
                onRightIconClick={() => setShowPassword(!showPassword)}
              />
              
              {/* Password strength indicator */}
              {password && (
                <div className="mt-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-gray-500 dark:text-gray-400">Password strength:</span>
                    <span className={passwordStrength.color}>
                      {passwordStrength.text}
                    </span>
                  </div>
                  <div className="mt-1 h-1 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div
                      className={`h-full transition-all duration-300 ${
                        passwordStrength.strength < 2
                          ? 'bg-red-500'
                          : passwordStrength.strength < 4
                          ? 'bg-yellow-500'
                          : passwordStrength.strength < 5
                          ? 'bg-blue-500'
                          : 'bg-green-500'
                      }`}
                      style={{ width: `${(passwordStrength.strength / 5) * 100}%` }}
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Confirm Password field */}
            <Input
              {...register('password_confirmation')}
              id="password_confirmation"
              type={showConfirmPassword ? 'text' : 'password'}
              label="Confirm password"
              placeholder="Confirm your password"
              required
              error={errors.password_confirmation?.message}
              leftIcon={Lock}
              rightIcon={showConfirmPassword ? EyeOff : Eye}
              onRightIconClick={() => setShowConfirmPassword(!showConfirmPassword)}
            />

            {/* Accept terms checkbox */}
            <div className="flex items-center">
              <input
                type="checkbox"
                checked={acceptTerms}
                onChange={(e) => setAcceptTerms(e.target.checked)}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="text-gray-600">
                <span className="ml-2 text-sm">I agree to the </span>
                <Link
                  to="/terms"
                  className="text-blue-600 hover:text-blue-500"
                >
                  Terms of Service
                </Link>
                <span className="text-sm"> and </span>
                <Link
                  to="/privacy"
                  className="text-blue-600 hover:text-blue-500"
                >
                  Privacy Policy
                </Link>
              </label>
            </div>

            {/* Global error */}
            {errors.root && (
              <div className="p-3 text-sm text-red-600 bg-red-50 rounded-lg">
                {errors.root.message}
              </div>
            )}

            {/* Submit button */}
            <Button
              type="submit"
              loading={isLoading}
              disabled={!acceptTerms}
              className="w-full"
              size="lg"
            >
              Create account
            </Button>
          </form>
        </Card.Body>

        <Card.Footer>
          <div className="text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link
                to="/login"
                className="font-medium text-blue-600 hover:text-blue-500"
              >
                Sign in
              </Link>
            </p>
          </div>
        </Card.Footer>
      </Card>

      {/* Security tips */}
      <Card className="mt-6">
        <Card.Body className="!py-4">
          <h3 className="text-sm font-medium text-gray-900 mb-3">
            Security Tips
          </h3>
          <div className="space-y-2">
            {[
              'Use a strong, unique password',
              'Enable two-factor authentication when available',
              'Never share your login credentials',
              'Log out from shared devices'
            ].map((tip, index) => (
              <div key={index} className="flex items-center text-xs text-gray-600">
                <div className="w-1.5 h-1.5 bg-blue-600 rounded-full mr-2" />
                {tip}
              </div>
            ))}
          </div>
        </Card.Body>
      </Card>
    </AuthLayout>
  )
}

export default Register 