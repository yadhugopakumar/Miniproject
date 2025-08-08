import React from 'react';

export default function MedRemindApp() {
  return (
    <div className="min-h-screen bg-white font-sans antialiased" >
      {/* Header/AppBar */}

      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <a href='/'>
              <h1 className="text-2xl font-bold text-white">MedRemind</h1>
            </a>
            <nav className="hidden md:flex space-x-6">
              <a href="#" className="text-green-100 hover:text-white transition-colors duration-200 font-medium">
                Dashboard
              </a>
              <a href="#" className="text-green-100 hover:text-white transition-colors duration-200 font-medium">
                Controls
              </a>
              <a href="#" className="text-green-100 hover:text-white transition-colors duration-200 font-medium">
                Settings
              </a>
            </nav>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" >
        {/* Hero Section */}
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold text-gray-900 mb-4 leading-tight">
            Parental Control Dashboard
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Monitor and manage your child's medication reminders with comprehensive parental controls
          </p>
        </div>

        {/* Card Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
          {/* Card 1 */}
          <div className="bg-white rounded-xl shadow-md border border-gray-100 p-6 hover:shadow-lg transition-shadow duration-200">
            <div className="flex items-center mb-4">
              <div className="bg-green-100 p-3 rounded-lg">
                <div className="w-6 h-6 bg-green-600 rounded"></div>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 ml-3">Active Reminders</h3>
            </div>
            <p className="text-gray-600 mb-4">Monitor active medication schedules</p>
            <button className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200">
              View Details
            </button>
          </div>

          {/* Card 2 */}
          <div className="bg-white rounded-xl shadow-md border border-gray-100 p-6 hover:shadow-lg transition-shadow duration-200">
            <div className="flex items-center mb-4">
              <div className="bg-green-100 p-3 rounded-lg">
                <div className="w-6 h-6 bg-green-600 rounded"></div>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 ml-3">Usage Reports</h3>
            </div>
            <p className="text-gray-600 mb-4">Track compliance and usage patterns</p>
            <button className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200">
              Generate Report
            </button>
          </div>

          {/* Card 3 */}
          <div className="bg-white rounded-xl shadow-md border border-gray-100 p-6 hover:shadow-lg transition-shadow duration-200">
            <div className="flex items-center mb-4">
              <div className="bg-green-100 p-3 rounded-lg">
                <div className="w-6 h-6 bg-green-600 rounded"></div>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 ml-3">Settings</h3>
            </div>
            <p className="text-gray-600 mb-4">Configure parental control preferences</p>
            <button className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200">
              Manage Settings
            </button>
          </div>
        </div>

        {/* Stats Section */}
        <div className="bg-gradient-to-r from-green-50 to-green-100 rounded-xl p-8 mb-8">
          <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">Quick Stats</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600 mb-2">12</div>
              <div className="text-gray-700 font-medium">Active Medications</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600 mb-2">95%</div>
              <div className="text-gray-700 font-medium">Compliance Rate</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600 mb-2">7</div>
              <div className="text-gray-700 font-medium">Days Streak</div>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <button className="bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-8 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200 shadow-md">
            Add New Reminder
          </button>
          <button className="bg-white hover:bg-gray-50 text-green-600 font-medium py-3 px-8 rounded-lg border-2 border-green-600 transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-green-200 shadow-md">
            View All Reports
          </button>
          <button className="bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium py-3 px-8 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-4 focus:ring-gray-200 shadow-md">
            Emergency Contact
          </button>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-50 border-t border-gray-200 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center text-gray-600">
            <p>&copy; 2024 MedRemind. Keeping families healthy and connected.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}