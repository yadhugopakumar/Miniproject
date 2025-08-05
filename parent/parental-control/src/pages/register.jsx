import React, { useState } from 'react';
import { supabase } from '../supabase/supabase-client';

export default function Register() {
  const [formData, setFormData] = useState({
    parentName: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: '',
    agreedToTerms: false
  });

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');

    if (formData.password !== formData.confirmPassword) {
      setErrorMsg("Passwords do not match");
      return;
    }

    if (!formData.agreedToTerms) {
      setErrorMsg("You must agree to the terms");
      return;
    }

    setLoading(true);

    try {
      // 1. Create Supabase Auth User
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password
      });

      if (signUpError) {
        setErrorMsg(signUpError.message);
        setLoading(false);
        return;
      }

      const userId = authData.user.id;

      // 2. Store additional parent info in 'parents' table
      const { error: dbError } = await supabase.from('parents').insert([
        {
          id: userId,
          name: formData.parentName,
          email: formData.email,
          phone: formData.phone
        }
      ]);

      if (dbError) {
        setErrorMsg(dbError.message);
      } else {
        setSuccessMsg('Account created successfully! Please verify your email.');
        setFormData({
          parentName: '',
          email: '',
          phone: '',
          password: '',
          confirmPassword: '',
          agreedToTerms: false
        });
      }
    } catch (err) {
      setErrorMsg('Unexpected error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white font-sans antialiased">
      {/* Header */}
      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-white">MedRemind</h1>
            <a href="/login" className="text-green-100 hover:text-white transition-colors duration-200 font-medium">
              Sign In
            </a>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white rounded-xl shadow-lg border border-gray-100 p-8">
          <div className="text-center mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Create Your Account</h2>
            <p className="text-gray-600">Set up parental controls for medication reminders</p>
          </div>

          {errorMsg && <div className="text-red-600 text-sm mb-4 text-center">{errorMsg}</div>}
          {successMsg && <div className="text-green-600 text-sm mb-4 text-center">{successMsg}</div>}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="bg-green-50 rounded-lg p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Parent Information</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Full Name *</label>
                  <input
                    type="text"
                    name="parentName"
                    value={formData.parentName}
                    onChange={handleInputChange}
                    required
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Phone Number *</label>
                  <input
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    required
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                  />
                </div>
              </div>

              <div className="mt-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">Email Address *</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Password *</label>
                <input
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Confirm Password *</label>
                <input
                  type="password"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleInputChange}
                  required
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg"
                />
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <input
                type="checkbox"
                name="agreedToTerms"
                checked={formData.agreedToTerms}
                onChange={handleInputChange}
                required
                className="mt-1 h-4 w-4 text-green-600"
              />
              <label className="text-sm text-gray-700">
                I agree to the <a href="#" className="text-green-600">Terms of Service</a> and <a href="#" className="text-green-600">Privacy Policy</a>
              </label>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-4 px-6 rounded-lg transition-colors duration-200"
            >
              {loading ? 'Creating Account...' : 'Create Account'}
            </button>

            <div className="text-center mt-6">
              <p className="text-gray-600">
                Already have an account? <a href="/login" className="text-green-600">Sign In</a>
              </p>
            </div>
          </form>
        </div>

        <div className="mt-8 bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center">
            <div className="w-5 h-5 bg-green-600 rounded-full mr-3"></div>
            <p className="text-sm text-green-800">
              Your data is encrypted and secure. We prioritize your family's privacy and safety.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
