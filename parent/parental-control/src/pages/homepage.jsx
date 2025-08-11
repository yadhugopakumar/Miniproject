

import { useState, useEffect } from "react";
import { supabase } from "../supabase/supabase-client"; // <-- adjust path
import { useNavigate } from "react-router-dom";
import MemberCardsGrid from "../components/memberscard";
import Header from "../components/header";

export default function Home() {
  const [showModal, setShowModal] = useState(false);
  const navigate = useNavigate();

  const [members, setMembers] = useState([]);
  const [refreshKey, setRefreshKey] = useState(0);

  // Add these states
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const [activecount, setActiveCount] = useState(0);

  // Fetch members whenever refreshKey changes
  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      setError(null);

      // Get current user once
      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser();

      if (userError || !user) {
        setError("User not logged in");
        setLoading(false);
        return;
      }

      try {
        // Run queries in parallel
        const [membersResponse, countResponse] = await Promise.all([
          supabase
            .from("child_users")
            .select("*")
            .eq("parent_id", user.id)
            .order("username", { ascending: true }),
          supabase
            .from("child_users")
            .select("id", { count: "exact", head: true })
            .eq("parent_id", user.id),
        ]);

        const [membersData, membersError] = [membersResponse.data, membersResponse.error];
        const [countData, countError] = [countResponse.count, countResponse.error];

        if (membersError) throw membersError;
        if (countError) throw countError;

        setMembers(membersData || []);
        setActiveCount(countData || 0);
      } catch (err) {
        console.error(err);
        setError(err.message || "Error fetching data");
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, [refreshKey]);


  // Callback to trigger refresh
  function handleMemberAdded() {
    setRefreshKey((prev) => prev + 1);
  }

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
      <Header onMemberAdded={handleMemberAdded} />
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
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center mb-12">

          <h2 className="text-4xl font-bold text-gray-900 mb-4 leading-tight  md:mt-4">
            Parental Control Dashboard
          </h2>

          {/* ----------------Stats Section ---------------------*/}
          <div className="bg-gradient-to-r from-green-50 to-green-100 rounded-xl p-8 mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
              Quick Stats
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600 mb-2">{activecount}</div>
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
          {/* ----------------Stats Section ---------------------*/}

        </div>

        <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          Members
        </h3>

        {loading && <div className="grid place-items-center">
          <div className="flex flex-col items-center justify-center">
            <div className="animate-spin rounded-full h-14 w-14 border-t-4 border-green-600"></div>
            <span className="mt-4 text-gray-700 font-medium">Loading child details...</span>
          </div>
        </div>
        }


        {/* -----showing dynamic chil users------------- */}
        {error && <div style={{ color: "red" }}>{error}</div>}
        {!loading && !error && <MemberCardsGrid members={members} />}
        {/* -----showing dynamic chil users------------- */}

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
