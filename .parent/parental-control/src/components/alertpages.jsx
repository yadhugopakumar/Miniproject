// Alert.jsx
export const Alert=({ type = "info", message, onClose }) =>{
    const colors = {
      info: "bg-blue-100 text-blue-700",
      success: "bg-green-100 text-green-700",
      error: "bg-red-100 text-red-700",
      warning: "bg-yellow-100 text-yellow-700",
    };
  
    const icons = {
      info: (
        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path d="M18 10c0 4.418-3.582 8-8 8s-8-3.582-8-8 3.582-8 8-8 8 3.582 8 8zM9 9v5h2v-5H9zm0-3h2v2H9V6z" />
        </svg>
      ),
      success: (
        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path d="M16.707 5.293a1 1 0 00-1.414 0L9 11.586 6.707 9.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l7-7a1 1 0 000-1.414z" />
        </svg>
      ),
      error: (
        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 8.586l4.95-4.95a1 1 0 011.414 1.414L11.414 10l4.95 4.95a1 1 0 01-1.414 1.414L10 11.414l-4.95 4.95a1 1 0 01-1.414-1.414L8.586 10l-4.95-4.95a1 1 0 011.414-1.414L10 8.586z" />
        </svg>
      ),
      warning: (
        <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path d="M8.257 3.099c.765-1.36 2.681-1.36 3.446 0l6.518 11.594c.75 1.335-.213 3.007-1.723 3.007H3.462c-1.51 0-2.473-1.672-1.723-3.007L8.257 3.1zM11 14a1 1 0 11-2 0 1 1 0 012 0zm-1-4a1 1 0 01-1-1V7a1 1 0 112 0v2a1 1 0 01-1 1z" />
        </svg>
      ),
    };
  
    return (
      <div
        className={`flex items-center p-4 rounded-md ${colors[type]} shadow-md max-w-md mx-auto`}
        role="alert"
      >
        {icons[type]}
        <span className="flex-1">{message}</span>
        {onClose && (
          <button
            onClick={onClose}
            className="ml-4 font-bold text-xl leading-none hover:text-gray-700"
            aria-label="Close alert"
          >
            &times;
          </button>
        )}
      </div>
    );
  }
  