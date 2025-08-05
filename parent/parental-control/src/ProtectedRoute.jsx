import { Navigate } from 'react-router-dom'
import { supabase } from './supabase/supabase-client'

const ProtectedRoute = ({ children }) => {
//   const session = supabase.auth.getSession()  // promise, or use useEffect
//   const user = supabase.auth.user()  // may be null
    const user ='yadhu'
  if (!user) {
    return <Navigate to="/login" />
  }
  return children
}

export default ProtectedRoute
