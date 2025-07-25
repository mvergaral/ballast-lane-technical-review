const Card = ({
  className = '',
  children,
  ...props
}) => {
  let cardClasses = 'bg-white rounded-xl shadow-lg border border-gray-200/50'
  
  if (className) {
    cardClasses += ' ' + className
  }

  return (
    <div className={cardClasses} {...props}>
      {children}
    </div>
  )
}

const CardHeader = ({
  className = '',
  children,
  ...props
}) => {
  let headerClasses = 'px-6 py-4 border-b border-gray-200'
  
  if (className) {
    headerClasses += ' ' + className
  }

  return (
    <div className={headerClasses} {...props}>
      {children}
    </div>
  )
}

const CardBody = ({
  className = '',
  children,
  ...props
}) => {
  let bodyClasses = 'px-6 py-4'
  
  if (className) {
    bodyClasses += ' ' + className
  }

  return (
    <div className={bodyClasses} {...props}>
      {children}
    </div>
  )
}

const CardFooter = ({
  className = '',
  children,
  ...props
}) => {
  let footerClasses = 'px-6 py-4 border-t border-gray-200'
  
  if (className) {
    footerClasses += ' ' + className
  }

  return (
    <div className={footerClasses} {...props}>
      {children}
    </div>
  )
}

Card.Header = CardHeader
Card.Body = CardBody
Card.Footer = CardFooter

export default Card
