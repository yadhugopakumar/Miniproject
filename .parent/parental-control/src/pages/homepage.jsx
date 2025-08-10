

import {  useState } from "react";
import { supabase } from "../supabase/supabase-client"; // <-- adjust path
import { useNavigate } from "react-router-dom";
import MemberCardsGrid from "../components/memberscard";
import Header from "../components/header";

export default function Home() {
  const [showModal, setShowModal] = useState(false);
  const navigate = useNavigate();

  // Handle logout confirmation
  const handleLogout = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      setShowModal(false);
      navigate("/login");
    } catch (err) {
      console.error("Error logging out:", err.message);
    }
  };
 
  return (
    <div className="min-h-screen bg-white font-sans antialiased">
      {/* Header */}
      <Header />

      {/* Logout Modal */}
      {showModal && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/20 z-50">
          <div className="bg-white rounded-lg p-6 w-80 shadow-lg">
            <h2 className="text-lg font-semibold mb-4">Confirm Logout</h2>
            <p className="text-gray-600 mb-6">
              Are you sure you want to log out?
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowModal(false)
                }
                className="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400"
              >
                Cancel
              </button>
              <button
                onClick={handleLogout}
                className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="text-center mb-12">
        
          <h2 className="text-4xl font-bold text-gray-900 mb-4 leading-tight">
            Parental Control Dashboard
          </h2>

          {/* Stats Section */}
          <div className="bg-gradient-to-r from-green-50 to-green-100 rounded-xl p-8 mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
              Quick Stats
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600 mb-2">4</div>
                <div className="text-gray-700 font-medium">Active Members</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-red-500 mb-2">3</div>
                <div className="text-gray-700 font-medium">
                  Missed Medications (Last 7 Days)
                </div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-yellow-500 mb-2">5</div>
                <div className="text-gray-700 font-medium">
                  Late Medications Taken
                </div>
              </div>
            </div>
          </div>
        </div>

        <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          Members
        </h3>

        <MemberCardsGrid />
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
