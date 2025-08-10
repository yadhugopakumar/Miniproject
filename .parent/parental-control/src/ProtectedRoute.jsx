

import { Navigate } from 'react-router-dom';

export default function ProtectedRoute({ session, children }) {
  if (!session) {
    return <Navigate to="/home" replace />;
  }
  return children;
}
