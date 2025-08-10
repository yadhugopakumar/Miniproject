// import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
// import { useState, useEffect } from 'react';
// import { supabase } from './supabase/supabase-client';
// import Login from './pages/login';
// import Register from './pages/register';
// import HomePage from './pages/homepage';
// import ProtectedRoute from './ProtectedRoute';
// import AuthListener from './supabase/authlitsener'; 

// function App() {
//   const [session, setSession] = useState(null);
//   const [loading, setLoading] = useState(true);

//   useEffect(() => {
//     // Get the initial session
//     supabase.auth.getSession().then(({ data: { session } }) => {
//       setSession(session);
//       setLoading(false);
//     });

//     // Listen for changes in auth state
//     const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
//       setSession(session);
//       setLoading(false);
//     });

//     return () => subscription.unsubscribe();
//   }, []);

//   if (loading) {
//     return <div className="h-screen flex items-center justify-center">Loading...</div>;
//   }

//   return (
//     <BrowserRouter>
//       {/* Global listener (logging, analytics, additional side effects) */}
//       <AuthListener />

//       <Routes>
//         {/* Public Routes */}
//         {!session && (
//           <>
//             <Route path="/login" element={<Login />} />
//             <Route path="/register" element={<Register />} />
//           </>
//         )}

//         {/* Protected Routes */}
//         <Route
//           path="/"
//           element={
//             <ProtectedRoute session={session}>
//               <HomePage />
//             </ProtectedRoute>
//           }
//         />

//         {/* Redirect unknown paths */}
//         <Route path="*" element={<Navigate to={session ? "/" : "/login"} />} />
//       </Routes>
//     </BrowserRouter>
//   );
// }

// export default App;
import { Routes, Route, Navigate } from "react-router-dom";
import PublicHome from "./pages/public-home";
import Login from "./pages/login";
import Signup from "./pages/register";
import Home from "./pages/homepage";
import ProtectedRoute from "./ProtectedRoute";
import ForgotPassword from "./pages/forgotpassword";
import ResetPassword from "./components/reset-password";
import UserProfile from "./pages/usermonitorpage";
import MedicineStockPage from "./pages/medicinestock";

export default function App({ session }) {
  return (
    <Routes>
      {/* Public homepage */}
      <Route
        path="/home"
        element={
          !session ? <PublicHome /> : <Navigate to="/" replace />
        }
      />
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/forgotpassword" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />
      <Route path="/profile/:id" element={<UserProfile />} />
      <Route path="/medicinestock" element={<MedicineStockPage />} />


      {/* Private dashboard/root - shows only when logged in */}
      <Route
        path="/"
        element={
          <ProtectedRoute session={session}>
            <Home />
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

