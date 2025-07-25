function Button({ 
  children, 
  variant = 'primary', 
  size = 'md', 
  className = '', 
  disabled = false, 
  loading = false,
  onClick,
  type = 'button',
  ...props 
}) {
  let classes = 'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed'
  
  switch (variant) {
    case 'primary':
      classes += ' bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500'
      break
    case 'secondary':
      classes += ' bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500'
      break
    case 'outline':
      classes += ' border border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-blue-500'
      break
    case 'ghost':
      classes += ' text-gray-600 hover:bg-gray-100 focus:ring-gray-500'
      break
    case 'danger':
      classes += ' bg-red-600 text-white hover:bg-red-700 focus:ring-red-500'
      break
    default:
      classes += ' bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500'
  }
  
  switch (size) {
    case 'sm':
      classes += ' px-3 py-1.5 text-sm'
      break
    case 'md':
      classes += ' px-4 py-2 text-sm'
      break
    case 'lg':
      classes += ' px-6 py-3 text-base'
      break
    case 'xl':
      classes += ' px-8 py-4 text-lg'
      break
    default:
      classes += ' px-4 py-2 text-sm'
  }
  
  if (loading) {
    classes += ' opacity-50 cursor-not-allowed'
  }
  
  if (className) {
    classes += ' ' + className
  }
  
  return (
    <button
      type={type}
      className={classes}
      disabled={disabled || loading}
      onClick={onClick}
      {...props}
    >
      {loading && (
        <div className="w-4 h-4 border border-current border-t-transparent rounded-full spin -ml-1 mr-3"></div>
      )}
      {children}
    </button>
  )
}

export default Button
