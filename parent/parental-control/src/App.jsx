
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
import AuthCallback from "./supabase/authcallback";

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
        <Route path="/authcallback" element={<AuthCallback />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Signup />} />
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

