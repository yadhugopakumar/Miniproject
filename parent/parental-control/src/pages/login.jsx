

import React, { useState, useEffect } from 'react';
import { supabase } from '../supabase/supabase-client';
import { useNavigate, Link } from 'react-router-dom';
import { FcGoogle } from "react-icons/fc";
import regimg from "../assets/regimg.png";
import Swal from 'sweetalert2'


export default function Login() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    rememberMe: false
  });

  const [loading, setLoading] = useState(false);

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };


  // ------------login with credentials method start -------------------------

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    const { email, password } = formData;

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    setLoading(false);

    if (error) {
      if (error.message === 'Invalid login credentials') {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "Incorrect email or password. Please try again",
          showConfirmButton: false,
          timer: 1000
        });
      } else if (error.message.includes('Email not confirmed')) {
        Swal.fire({
          position: "top-end",
          icon: "error",
          title: "Please verify your email before logging in",
          showConfirmButton: false,
          timer: 1000
        });
      } else {
        Swal.fire({
          position: "top-end",
          icon: "error",
          title: 'Login failed: ' + error.message,
          showConfirmButton: false,
          timer: 1000
        });
      }
    } else {
      Swal.fire({
        position: "top-end",
        icon: "success",
        title: "Login Success",
        showConfirmButton: false,
        timer: 1000
      });
      navigate("/"); // Send to dashboard after login

    }
  };
  // ------------login with credentials method end -------------------------

  // ------------login with google auth method start -------------------------

  const handleGoogleLogin = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        // redirectTo: window.location.origin
        redirectTo: `${window.location.origin}/authcallback`,
      }
    });
    if (error) {
      Swal.fire({
        position: "top-end",
        icon: "error",
        title: "Login error" + error.message,
        showConfirmButton: false,
        timer: 1000
      });
    }
  };
  // ------------login with google auth method end -------------------------


  return (
    <div className="min-h-screen bg-white font-sans antialiased" style={{ backgroundColor: " rgb(244, 252, 245)" }}>

      {/* Header */}
      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-2">
            <h1 className="text-base font-semibold text-white">MedRemind</h1>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="bg-white rounded-xl shadow-lg border border-gray-100 flex flex-col lg:flex-row overflow-hidden">

          {/* Form Section */}
          <div className="w-full lg:w-1/2 p-8">
            <div className="text-center mb-8">
              <h2 className="text-3xl font-bold text-gray-900 mb-2">Welcome Back</h2>
              <p className="text-gray-600">Sign in to access your parental controls</p>
            </div>

            {/* ---------------------signin form template -------------------------- */}
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-4 focus:ring-green-200 focus:border-green-500 transition-colors duration-200"
                  placeholder="Enter your email"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Password</label>
                <input
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-4 focus:ring-green-200 focus:border-green-500 transition-colors duration-200"
                  placeholder="Enter your password"
                  required
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">

                </div>
                <Link to="/forgotpassword" className="text-sm text-green-600 hover:text-green-700 font-medium" style={{ color: "green" }}>Forgot password?</Link>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200 shadow-md"
              >
                {loading ? 'Signing In...' : 'Sign In'}
              </button>

              {/* Divider */}
              <div className="relative my-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-300"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-2 bg-white " >Or continue with</span>
                </div>
              </div>

              {/* Social Buttons */}
              <div className="space-y-3">
                <button type="button" className="w-full bg-white hover:bg-100 font-medium py-3 px-6 rounded-lg border border-gray-300 transition-colors duration-200 flex items-center justify-center" style={{ color: "black" }}
                  onClick={handleGoogleLogin}
                >
                  <div className="w-5 h-5 bg-white rounded mr-3" style={{ display: "grid", placeItems: "center" }}>
                    <FcGoogle />
                  </div>
                  Continue with Google
                </button>
              </div>

              {/* Register */}
              <div className="text-center mt-6">
                <p className="text-gray-600">
                  Don't have an account?{' '}
                  <Link to="/register" className="text-green-600 hover:text-green-700 font-medium" style={{ color: "green" }}>
                    Create Account
                  </Link>
                </p>
              </div>
            </form>
            {/* ---------------------signin form template -------------------------- */}


          </div>

          {/* Side Image Section */}
          <div className="hidden lg:block lg:w-1/2 bg-green-50 p-6 space-y-6">
            <img
              src={regimg}
              alt="Medicine Reminder"
              className="w-full h-auto object-contain"
            />

            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <div className="flex items-center">
                <div className="w-5 h-5 bg-green-600 rounded-full mr-3"></div>
                <p className="text-sm text-green-800 font-medium">
                  Secure medication tracking for your family
                </p>
              </div>
            </div>

            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <div className="flex items-center">
                <div className="w-5 h-5 bg-green-600 rounded-full mr-3"></div>
                <p className="text-sm text-green-800 font-medium">
                  Real-time parental control dashboard
                </p>
              </div>
            </div>
          </div>

        </div>
      </main>
    </div>
  );
}

