

import { useState } from "react";
import { supabase } from "../supabase/supabase-client"; // <-- adjust path
import { useNavigate } from "react-router-dom";
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
      <Header onLogoutClick={() => setShowModal(true)} />

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
                onClick={() => setShowModal(false)}
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
