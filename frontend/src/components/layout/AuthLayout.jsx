import { BookOpen } from 'lucide-react'

const AuthLayout = ({ children, title, subtitle }) => {
  return (
    <div className="min-h-screen flex">
      {/* Left side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-blue-600 to-blue-800 relative">
        <div className="absolute inset-0 bg-black/10" />
        <div className="relative flex flex-col justify-center px-12 text-white">
          <div className="flex items-center mb-8">
            <BookOpen size={48} className="mr-4" />
            <div>
              <h1 className="text-3xl font-bold">Library System</h1>
              <p className="text-blue-100">Professional Management</p>
            </div>
          </div>
          
          <h2 className="text-4xl font-bold mb-6">
            Welcome to the Future of Library Management
          </h2>
          
          <p className="text-lg text-blue-100 mb-8 leading-relaxed">
            Streamline your library operations with our comprehensive management system. 
            Handle books, borrowings, and users with ease and efficiency.
          </p>
          
          <div className="space-y-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-white rounded-full mr-3" />
              <span>Easy book catalog management</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-white rounded-full mr-3" />
              <span>Automated borrowing system</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-white rounded-full mr-3" />
              <span>Real-time analytics and reports</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-white rounded-full mr-3" />
              <span>Multi-role user management</span>
            </div>
          </div>
        </div>
        
        {/* Decorative elements */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -translate-y-32 translate-x-32" />
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-white/5 rounded-full translate-y-48 -translate-x-48" />
      </div>

      {/* Right side - Auth form */}
      <div className="flex-1 flex flex-col">
        {/* Content */}
        <div className="flex-1 flex items-center justify-center px-6 sm:px-12">
          <div className="w-full max-w-md space-y-8">
            {/* Mobile branding */}
            <div className="lg:hidden text-center">
              <div className="flex justify-center mb-4">
                <BookOpen size={32} className="text-blue-600" />
              </div>
              <h1 className="text-2xl font-bold text-gray-900">
                Library System
              </h1>
            </div>

            {/* Form header */}
            <div className="text-center">
              <h2 className="text-3xl font-bold text-gray-900">
                {title}
              </h2>
              {subtitle && (
                <p className="mt-2 text-gray-600">
                  {subtitle}
                </p>
              )}
            </div>

            {/* Form content */}
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}

export default AuthLayout 