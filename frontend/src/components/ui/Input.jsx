import { forwardRef } from 'react'
import { cn } from '../../lib/utils'

const Input = forwardRef(({
  className = '',
  type = 'text',
  label,
  error,
  hint,
  required = false,
  disabled = false,
  leftIcon: LeftIcon,
  rightIcon: RightIcon,
  onRightIconClick,
  ...props
}, ref) => {
  // Clases base del input usando Tailwind CSS
  const inputClasses = cn(
    // Estilos base
    "flex h-10 w-full rounded-md border border-input bg-background py-2 text-sm",
    "file:border-0 file:bg-transparent file:text-sm file:font-medium",
    "placeholder:text-muted-foreground",
    // Estados de interacción
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
    "disabled:cursor-not-allowed disabled:opacity-50",
    // Transiciones suaves
    "transition-colors duration-200",
    // Padding condicional basado en iconos
    LeftIcon && RightIcon ? "px-10" : LeftIcon ? "pl-10 pr-3" : RightIcon ? "pl-3 pr-10" : "px-3",
    // Estados de error
    error && "border-destructive focus-visible:ring-destructive",
    // Tema oscuro
    "dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100",
    "dark:placeholder:text-gray-400",
    "dark:focus-visible:ring-blue-500",
    error && "dark:border-red-500 dark:focus-visible:ring-red-500",
    className
  )

  const labelClasses = cn(
    "block text-sm font-medium leading-6 mb-2",
    "text-gray-900 dark:text-gray-100",
    error && "text-destructive dark:text-red-400"
  )

  const hintClasses = cn(
    "mt-2 text-sm",
    "text-muted-foreground dark:text-gray-400"
  )

  const errorClasses = cn(
    "mt-2 text-sm",
    "text-destructive dark:text-red-400"
  )

  const iconClasses = cn(
    "absolute top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500",
    "transition-colors duration-200"
  )

  const leftIconClasses = cn(iconClasses, "left-3")
  const rightIconClasses = cn(
    iconClasses, 
    "right-3",
    onRightIconClick && "cursor-pointer hover:text-gray-600 dark:hover:text-gray-300"
  )

  return (
    <div className="space-y-1">
      {label && (
        <label 
          htmlFor={props.id}
          className={labelClasses}
        >
          {label}
          {required && (
            <span className="ml-1 text-destructive dark:text-red-400" aria-label="requerido">
              *
            </span>
          )}
        </label>
      )}
      
      <div className="relative">
        {LeftIcon && (
          <LeftIcon 
            size={18} 
            className={leftIconClasses}
          />
        )}
        
        <input
          type={type}
          className={inputClasses}
          ref={ref}
          disabled={disabled}
          aria-invalid={error ? 'true' : 'false'}
          aria-describedby={
            error ? `${props.id}-error` : hint ? `${props.id}-hint` : undefined
          }
          {...props}
        />
        
        {RightIcon && (
          <RightIcon 
            size={18} 
            className={rightIconClasses}
            onClick={onRightIconClick}
          />
        )}
      </div>
      
      {hint && !error && (
        <p 
          id={`${props.id}-hint`}
          className={hintClasses}
        >
          {hint}
        </p>
      )}
      
      {error && (
        <p 
          id={`${props.id}-error`}
          className={errorClasses}
          role="alert"
        >
          {error}
        </p>
      )}
    </div>
  )
})

Input.displayName = "Input"

export default Input
