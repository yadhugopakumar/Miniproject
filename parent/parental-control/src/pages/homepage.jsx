
import { useState, useEffect } from "react";
import { supabase } from "../supabase/supabase-client";
import { useNavigate } from "react-router-dom";
import MemberCardsGrid from "../components/memberscard";
import Header from "../components/header";
import { format, subDays } from "date-fns"; // Import for date calculation

export default function Home() {
  const [showModal, setShowModal] = useState(false);
  const navigate = useNavigate();

  const [members, setMembers] = useState([]);
  const [refreshKey, setRefreshKey] = useState(0);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Use a single state object for the dynamic history counts
  const [historyStats, setHistoryStats] = useState({ missed: 0, late: 0, activeMembers: 0 });

  // Fetch members and stats whenever refreshKey changes
  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      setError(null);

      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser();

      if (userError || !user) {
        setError("User not logged in");
        setLoading(false);
        return;
      }
      sessionStorage.setItem("user_id", user.id);
      const userId = user.id;

      try {
        // --- 1. Fetch ALL child IDs first ---
        const { data: childData, error: childIdError } = await supabase
          .from("child_users")
          .select("id")
          .eq("parent_id", userId);

        if (childIdError) throw childIdError;

        const childIds = childData?.map(c => c.id) || [];
        const sevenDaysAgo = format(subDays(new Date(), 7), 'yyyy-MM-dd');

        let initialMembers = [];
        let missedCount = 0;
        let lateCount = 0;

        // Run primary queries in parallel
        if (childIds.length > 0) {

          // --- NEW: Prepare array of individual history promises for each child ---
          const individualStatPromises = childIds.flatMap(id => [
            // 1. Taken Count (Last 7 Days)
            supabase.from("history_entry")
              .select("id", { count: "exact", head: true })
              .eq('child_id', id)
              .eq('status', 'taken')
              .gte('date', sevenDaysAgo)
              .then(res => ({ id: id, status: 'taken', count: res.count, error: res.error })),

            // 2. Missed Count (Last 7 Days)
            supabase.from("history_entry")
              .select("id", { count: "exact", head: true })
              .eq('child_id', id)
              .eq('status', 'missed')
              .gte('date', sevenDaysAgo)
              .then(res => ({ id: id, status: 'missed', count: res.count, error: res.error })),

            // 3. Late Count (Last 7 Days)
            supabase.from("history_entry")
              .select("id", { count: "exact", head: true })
              .eq('child_id', id)
              .eq('status', 'takenLate')
              .gte('date', sevenDaysAgo)
              .then(res => ({ id: id, status: 'late', count: res.count, error: res.error })),
          ]);
          // --------------------------------------------------------------------------

          const [
            membersResponse,
            missedAggregateResponse,
            lateAggregateResponse,
            ...individualStatsResults
          ] = await Promise.all([
            // 1. Fetch Members List
            supabase
              .from("child_users")
              .select("*", { count: "exact" })
              .eq("parent_id", userId)
              .order("username", { ascending: true }),

            // 2. Aggregate Missed Doses
            supabase
              .from("history_entry")
              .select("id", { count: "exact", head: true })
              .in('child_id', childIds)
              .eq('status', 'missed')
              .gte('date', sevenDaysAgo),

            // 3. Aggregate Late Doses
            supabase
              .from("history_entry")
              .select("id", { count: "exact", head: true })
              .in('child_id', childIds)
              .eq('status', 'takenLate')
              .gte('date', sevenDaysAgo),

            // --- NEW: Spread the individual stat promises here ---
            ...individualStatPromises,
          ]);

          // ... (Error Checking for aggregate responses)

          // --- NEW: Process individual stat results ---
          const statsMap = individualStatsResults.reduce((acc, result) => {
            if (result.error) {
              console.error(`Error fetching individual stat for child ${result.id} (${result.status}):`, result.error);
              return acc;
            }
            acc[result.id] = acc[result.id] || { missed: 0, taken: 0, late: 0 };
            acc[result.id][result.status] = result.count || 0;
            return acc;
          }, {});

          initialMembers = membersResponse.data.map(member => ({
            ...member,
            stats: statsMap[member.id] || { missed: 0, taken: 0, late: 0 }
          }));
          // -----------------------------------------------------------

          // ... (rest of the state setting)
          setMembers(initialMembers);
          setHistoryStats({
            missed: missedAggregateResponse.count || 0,
            late: lateAggregateResponse.count || 0,
            activeMembers: membersResponse.count || 0,
          });
        } else {
          // If no children exist, set everything to zero/empty
          setMembers([]);
          setHistoryStats({ missed: 0, late: 0, activeMembers: 0 });
        }
      } catch (err) {
        console.error("Dashboard Fetch Error:", err);
        setError(err.message || "Error fetching dashboard data.");
        setMembers([]);
        setHistoryStats({ missed: 0, late: 0, activeMembers: 0 });
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

          {/* ----------------Dynamic Stats Section ---------------------*/}
          <div className="bg-gradient-to-r from-green-50 to-green-100 rounded-xl p-8 mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">
              Quick Stats
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-600 mb-2">{historyStats.activeMembers}</div>
                <div className="text-gray-700 font-medium">Active Members</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-red-500 mb-2">{historyStats.missed}</div>
                <div className="text-gray-700 font-medium">
                  Missed Medications (Last 7 Days)
                </div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-yellow-500 mb-2">{historyStats.late}</div>
                <div className="text-gray-700 font-medium">
                  Late Medications Taken (Last 7 Days)
                </div>
              </div>
            </div>
            {historyStats.activeMembers > 0 && (
              <p className="text-sm text-gray-500 mt-4">
                *Counts reflect aggregate medicine history for all members over the past 7 days.
              </p>
            )}
          </div>
          {/* ----------------Dynamic Stats Section ---------------------*/}

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
        {!loading && !error && members.length === 0 && (
          <div className="text-center py-10 text-gray-500">
            You have not added any child members yet.
          </div>
        )}
        {!loading && !error && members.length > 0 && <MemberCardsGrid members={members} />}
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