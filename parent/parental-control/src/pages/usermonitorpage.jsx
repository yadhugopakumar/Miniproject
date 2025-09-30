
import { Link, useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { supabase } from "../supabase/supabase-client";
import Swal from "sweetalert2";
import "chart.js/auto";
import MedicineStats from "../components/medicinestats";
import HealthReports from "../components/healthreports";

export default function ProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [child, setChild] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editFormData, setEditFormData] = useState({ username: "", age: "", phone: "" });

  const [medHistory, setMedHistory] = useState([]); // Array of medicine intake details

  // Fetch child details
  useEffect(() => {
    async function fetchChild() {
      setLoading(true);
      setError(null);
      const { data, error } = await supabase.from("child_users").select("*").eq("id", id).single();
      if (error) setError("Failed to load child details");
      else setChild(data);
      setLoading(false);
    }
    fetchChild();
  }, [id]);
  // Fetch medicine history for the child
  useEffect(() => {
    async function fetchMedHistory() {
      const { data, error } = await supabase
        .from("history_entry")
        .select("*")
        .eq("child_id", id);

      if (!error && data) {
        setMedHistory(data);
      }
    }
    fetchMedHistory();
  }, [id]);

  // Aggregate counts
  const aggregatedCounts = medHistory.reduce((acc, entry) => {
    const medName = entry.medicine_name;
    if (!acc[medName]) acc[medName] = { taken: 0, missed: 0, late: 0, details: [] };
    if (entry.status === "taken") acc[medName].taken++;
    if (entry.status === "missed") acc[medName].missed++;
    if (entry.status === "takenLate") acc[medName].late++;
    acc[medName].details.push({ date: entry.date, time: entry.time, status: entry.status });
    return acc;
  }, {});

  const pieData = {
    labels: ["Taken", "Missed", "Taken Late"],
    datasets: [{
      data: [
        medHistory.filter(e => e.status === "taken").length,
        medHistory.filter(e => e.status === "missed").length,
        medHistory.filter(e => e.status === "takenLate").length
      ],
      backgroundColor: ["#16a34a", "#dc2626", "#f59e0b"],
    }]
  };

  const handleEdit = () => {
    setEditFormData({ username: child.username, age: child.age || "", phone: child.child_phone });
    setIsEditing(true);
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    const { username, age, phone } = editFormData;

    if (!username.trim()) {
      Swal.fire({ position: "top-end", icon: "warning", title: "Name cannot be empty.", showConfirmButton: false, timer: 1000 });
      setLoading(false); return;
    }
    const parsedAge = parseInt(age, 10);
    if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 100) {
      Swal.fire({ position: "top-end", icon: "warning", title: "Enter valid age.", showConfirmButton: false, timer: 1000 });
      setLoading(false); return;
    }
    if (!phone.trim() || !/^\d{10}$/.test(phone.trim())) {
      Swal.fire({ position: "top-end", icon: "warning", title: "Enter valid 10-digit phone.", showConfirmButton: false, timer: 1000 });
      setLoading(false); return;
    }

    try {
      const { error: updateError } = await supabase.from("child_users")
        .update({ username: username.trim(), age: parsedAge, child_phone: phone.trim() })
        .eq("id", child.id);
      if (updateError) throw updateError;

      const { data: freshData, error: fetchError } = await supabase.from("child_users").select("*").eq("id", child.id).single();
      if (fetchError) throw fetchError;
      setChild(freshData);

      Swal.fire({ position: "top-end", icon: "success", title: "Updated successfully", showConfirmButton: false, timer: 1000 });
      setIsEditing(false);
    } catch (err) {
      console.error(err);
      Swal.fire({ position: "top-end", icon: "error", title: "Update failed", showConfirmButton: false, timer: 1000 });
    } finally { setLoading(false); }
  };

  const handleDelete = async () => {
    const result = await Swal.fire({
      title: "Are you sure?",
      text: "You won't be able to revert this!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, delete it!",
    });
    if (!result.isConfirmed) return;

    setDeleting(true);
    const { error } = await supabase.from("child_users").delete().eq("id", id);
    setDeleting(false);
    if (error) Swal.fire({ position: "top-end", icon: "error", title: "Failed to delete", showConfirmButton: false, timer: 1500 });
    else { Swal.fire({ position: "top-end", icon: "success", title: "Deleted successfully", showConfirmButton: false, timer: 1500 }); navigate("/"); }
  };

  if (loading) return (
    <div className="grid place-items-center h-screen">
      <div className="flex flex-col items-center justify-center">
        <div className="animate-spin rounded-full h-14 w-14 border-t-4 border-green-600"></div>
        <span className="mt-4 text-gray-700 font-medium">Loading child details...</span>
      </div>
    </div>
  );
  if (error) return <div className="p-8 text-center text-red-600">{error}</div>;
  if (!child) return <div className="p-8 text-center">No child found.</div>;

  // Sample stats, replace with real data
  const missedMedicine = 2;
  const takenMedicine = 25;
  const lateMedicine = 1;
  const healthReports = { bloodPressure: "120/80 mmHg", cholesterol: "180 mg/dL", bloodSugar: "90 mg/dL" };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center py-4">
          <Link to="/" className="text-white font-bold text-2xl">MedRemind</Link>
          <button onClick={() => navigate(-1)} className="text-white bg-green-700 hover:bg-green-800 px-3 py-1 rounded">← Back</button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto mt-8 space-y-6 p-4">
        {/* Child Info */}
        <section className="bg-white shadow rounded p-6">
          <div className="flex justify-between items-start">
            <div>
              <h2 className="text-2xl font-semibold">{child.username}</h2>
              <p className="mt-1"><strong>Age:</strong> {child.age ?? "N/A"}</p>
              <p className="mt-1"><strong>Phone:</strong> {child.child_phone ?? "N/A"}</p>
            </div>
            <div className="flex space-x-3">
              <button onClick={handleEdit} className="px-4 py-2 bg-yellow-400 hover:bg-yellow-500 text-white rounded shadow">Edit</button>
              <button onClick={handleDelete} disabled={deleting} className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded shadow disabled:opacity-50">
                {deleting ? "Deleting..." : "Delete"}
              </button>
            </div>
          </div>
        </section>

        {/* Medicine Stats */}

        <MedicineStats childId={child.id} username={child.username} />
        {/* Medicine Stats */}


        {/* Health Reports */}

        <HealthReports childId={child.id} username={child.username} />
        {/* Health Reports */}

      </main>

      {/* Edit Modal */}
      {isEditing && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50">
          <form onSubmit={handleEditSubmit} className="space-y-4 p-6 border rounded bg-white max-w-sm w-full shadow-lg">
            <h3 className="text-lg font-semibold mb-2">Edit Child Details</h3>
            <div>
              <label className="block font-semibold mb-1">Name</label>
              <input type="text" value={editFormData.username} onChange={e => setEditFormData({ ...editFormData, username: e.target.value })} className="border rounded px-3 py-2 w-full" required />
            </div>
            <div>
              <label className="block font-semibold mb-1">Phone</label>
              <input type="tel" value={editFormData.phone} onChange={e => setEditFormData({ ...editFormData, phone: e.target.value })} className="border rounded px-3 py-2 w-full" required />
            </div>
            <div>
              <label className="block font-semibold mb-1">Age</label>
              <input type="number" value={editFormData.age} onChange={e => setEditFormData({ ...editFormData, age: e.target.value })} min={1} max={100} className="border rounded px-3 py-2 w-full" />
            </div>
            <div className="flex justify-end space-x-3">
              <button type="button" onClick={() => { setIsEditing(false); setEditFormData({ username: "", age: "", phone: "" }); }} className="px-4 py-2 rounded bg-gray-800 hover:bg-gray-600 text-white">Cancel</button>
              <button type="submit" className="px-4 py-2 rounded bg-yellow-500 hover:bg-yellow-600 text-white">Save</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
