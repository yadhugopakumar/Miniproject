
// import { Link, useNavigate, useParams } from "react-router-dom";
// import { useEffect, useState } from "react";
// import { supabase } from "../supabase/supabase-client";
// import Swal from "sweetalert2";

// export default function ProfilePage() {
//   const { id } = useParams();
//   const navigate = useNavigate();

//   const [child, setChild] = useState(null);
//   const [loading, setLoading] = useState(true);
//   const [error, setError] = useState(null);
//   const [deleting, setDeleting] = useState(false);
//   const [isEditing, setIsEditing] = useState(false);

//   const [editFormData, setEditFormData] = useState({
//     username: "",
//     age: "",
//     phone: "",
//   });


//   // ------------------------function for loaing details of child start------------------------------
//   useEffect(() => {
//     async function fetchChild() {
//       setLoading(true);
//       setError(null);
//       const { data, error } = await supabase
//         .from("child_users")
//         .select("*")
//         .eq("id", id)
//         .single();

//       if (error) {
//         setError("Failed to load child details");
//       } else {
//         setChild(data);
//       }
//       setLoading(false);
//     }
//     fetchChild();
//   }, [id]);

//   const handleEdit = () => {
//     setEditFormData({
//       username: child.username,
//       age: child.age || "",
//       phone: child.child_phone,
//     });
//     setIsEditing(true);
//   };
//   // ------------------------function for loading details of child end------------------------------

//   // ------------------------function for editing details of child start------------------------------

//   const handleEditSubmit = async (e) => {
//     e.preventDefault();
//     setLoading(true);
//     try {
//       // Update child
//       const { username, age, phone } = editFormData;
//       // Name validation
//       if (!username.trim()) {
//         Swal.fire({
//           position: "top-end",
//           icon: "warning",
//           title: "Name cannot be empty.",
//           showConfirmButton: false,
//           timer: 1000
//         });
//         setLoading(false); // Make sure to stop loading if there's an error
//         return;
//       }

//       // Age validation
//       const parsedAge = parseInt(age, 10);
//       if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 100) {
//         Swal.fire({
//           position: "top-end",
//           icon: "warning",
//           title: "Please enter a valid age.",
//           showConfirmButton: false,
//           timer: 1000
//         });
//         setLoading(false);
//         return;
//       }

//       // Phone validation
//       if (!phone.trim() || !/^\d{10}$/.test(phone.trim())) {
//         Swal.fire({
//           position: "top-end",
//           icon: "warning",
//           title: "Please enter a valid 10-digit phone number.",
//           showConfirmButton: false,
//           timer: 1000
//         });
//         setLoading(false);
//         return;
//       }

//       // Proceed with the update if all validations pass
//       const { error: updateError } = await supabase
//         .from("child_users")
//         .update({
//           username: username.trim(),
//           age: parsedAge,
//           child_phone: phone.trim()
//         })
//         .eq("id", child.id);




//       if (updateError) throw updateError;

//       // Refetch updated data
//       const { data: freshData, error: fetchError } = await supabase
//         .from("child_users")
//         .select("*")
//         .eq("id", child.id)
//         .single();

//       if (fetchError) throw fetchError;

//       setChild(freshData);

//       Swal.fire({
//         position: "top-end",
//         icon: "success",
//         title: "Data updated successfully",
//         showConfirmButton: false,
//         timer: 1000,
//       });

//       setIsEditing(false);
//     } catch (err) {
//       console.error(err);
//       Swal.fire({
//         position: "top-end",
//         icon: "error",
//         title: "Failed to update child user",
//         showConfirmButton: false,
//         timer: 1000,
//       });
//     } finally {
//       setLoading(false);
//     }
//   };
//   // ------------------------function for editing details of child end------------------------------
//   // ------------------------function for deleting details of child start------------------------------

//   async function handleDelete() {
//     const result = await Swal.fire({
//       title: "Are you sure?",
//       text: "You won't be able to revert this!",
//       icon: "warning",
//       showCancelButton: true,
//       confirmButtonColor: "#d33",
//       cancelButtonColor: "#3085d6",
//       confirmButtonText: "Yes, delete it!",
//       cancelButtonText: "Cancel",
//     });

//     if (!result.isConfirmed) return;

//     setDeleting(true);
//     const { error } = await supabase.from("child_users").delete().eq("id", id);
//     setDeleting(false);

//     if (error) {
//       Swal.fire({
//         position: "top-end",
//         icon: "error",
//         title: "Failed to delete member: " + error.message,
//         showConfirmButton: false,
//         timer: 1500,
//       });
//     } else {
//       Swal.fire({
//         position: "top-end",
//         icon: "success",
//         title: "Member deleted successfully.",
//         showConfirmButton: false,
//         timer: 1500,
//       });
//       navigate("/");
//     }
//   }
//   // ------------------------function for deleting details of child end------------------------------

//   if (loading)
//     return (
//       <div className="grid place-items-center h-screen">
//         <div className="flex flex-col items-center justify-center">
//           <div className="animate-spin rounded-full h-14 w-14 border-t-4 border-green-600"></div>
//           <span className="mt-4 text-gray-700 font-medium">
//             Loading child details...
//           </span>
//         </div>
//       </div>
//     );

//   if (error) return <div className="p-8 text-center text-red-600">{error}</div>;
//   if (!child) return <div className="p-8 text-center">No child found.</div>;

//   // Placeholder data for health tracker, replace with real data
//   const missedMedicine = 2;
//   const takenMedicine = 25;
//   const healthReports = {
//     bloodPressure: "120/80 mmHg",
//     cholesterol: "180 mg/dL",
//     bloodSugar: "90 mg/dL",
//   };

//   return (
//     <div>
//       <header className="bg-green-600 shadow-lg">
//         <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
//           <div className="flex justify-between items-center py-4">
//             <Link to="/" className="text-white font-bold text-2xl">
//               MedRemind
//             </Link>
//             <button
//               onClick={() => navigate(-1)}
//               className="text-white bg-green-700 hover:bg-green-800 px-3 py-1 rounded"
//             >
//               ← Back
//             </button>
//           </div>
//         </div>
//       </header>

//       <div className="max-w-3xl mx-auto p-6 bg-white shadow rounded mt-8">
//         <section className="mb-10">
//           <h2 className="text-2xl font-semibold mb-4">{child.username}</h2>
//           <p className="mb-2">
//             <strong>Age:</strong> {child.age ?? "N/A"}
//           </p>
//           <p className="mb-2">
//             <strong>Phone:</strong> {child.child_phone ?? "N/A"}
//           </p>
//           <div className="mt-6 flex space-x-4">
//             <button
//               onClick={handleEdit}
//               className="px-4 py-2 bg-yellow-400 hover:bg-yellow-500 text-white rounded shadow"
//             >
//               Edit
//             </button>
//             <button
//               onClick={handleDelete}
//               disabled={deleting}
//               className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded shadow disabled:opacity-50"
//             >
//               {deleting ? "Deleting..." : "Delete"}
//             </button>
//           </div>
//         </section>

//         <section className="bg-green-50 rounded-lg p-6">
//           <h3 className="text-xl font-semibold mb-4">Health Tracker</h3>
//           <div className="grid grid-cols-3 gap-6 mb-6 text-center">
//             <div>
//               <div className="text-lg font-bold text-red-600">{missedMedicine}</div>
//               <div className="text-sm font-medium text-gray-700">Missed Medicine</div>
//             </div>
//             <div>
//               <div className="text-lg font-bold text-green-600">{takenMedicine}</div>
//               <div className="text-sm font-medium text-gray-700">Taken Medicine</div>
//             </div>
//             <div>
//               <div className="text-lg font-bold text-yellow-500">1</div>
//               <div className="text-sm font-medium text-gray-700">Late Medicine</div>
//             </div>
//           </div>

//           <div className="space-y-3">
//             <div>
//               <strong>Blood Pressure:</strong> {healthReports.bloodPressure}
//             </div>
//             <div>
//               <strong>Cholesterol:</strong> {healthReports.cholesterol}
//             </div>
//             <div>
//               <strong>Blood Sugar:</strong> {healthReports.bloodSugar}
//             </div>
//           </div>
//         </section>
//       </div>


//       {/* ------------------------child details editing form modal start------------------------------ */}

//       {isEditing && (
//         <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50">
//           <form
//             onSubmit={handleEditSubmit}
//             className="space-y-4 p-6 border rounded bg-white max-w-sm w-full shadow-lg"
//           >
//             <div>
//               <label className="block font-semibold mb-1">Name</label>
//               <input
//                 type="text"
//                 name="username"
//                 value={editFormData.username}
//                 onChange={(e) =>
//                   setEditFormData({ ...editFormData, username: e.target.value })
//                 }
//                 className="border rounded px-3 py-2 w-full"
//                 required
//               />
//             </div>
//             <div>
//               <label className="block font-semibold mb-1">Phone</label>
//               <input
//                 type="tel"
//                 name="phone"
//                 value={editFormData.phone}
//                 onChange={(e) =>
//                   setEditFormData({ ...editFormData, phone: e.target.value })
//                 }
//                 // pattern="[0-9]{10}" // adjust if you want country code
//                 className="border rounded px-3 py-2 w-full"
//                 required
//               />
//             </div>

//             <div>
//               <label className="block font-semibold mb-1">Age</label>
//               <input
//                 type="number"
//                 name="age"
//                 value={editFormData.age}
//                 onChange={(e) =>
//                   setEditFormData({ ...editFormData, age: e.target.value })
//                 }
//                 min={1}
//                 max={100}
//                 className="border rounded px-3 py-2 w-full"
//               />
//             </div>
//             <div className="flex justify-end space-x-3">
//               <button
//                 type="button"
//                 onClick={() => {
//                   setIsEditing(false);
//                   setEditFormData({
//                     username: "",
//                     age: "",
//                     phone: "",
//                   });
//                 }}
//                 className="px-4 py-2 rounded bg-gray-800 hover:bg-gray-600 text-white"
//               >
//                 Cancel
//               </button>
//               <button
//                 type="submit"
//                 className="px-4 py-2 rounded bg-yellow-500 hover:bg-yellow-600 text-white"
//               >
//                 Save
//               </button>
//             </div>
//           </form>
//         </div>
//       )}
//       {/* ------------------------child details editing form modal end------------------------------ */}

//     </div>
//   );
// }
import { Link, useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { supabase } from "../supabase/supabase-client";
import Swal from "sweetalert2";
import { Pie } from "react-chartjs-2";
import jsPDF from "jspdf";
import "chart.js/auto";
import dayjs from "dayjs";
import MedicineStats from "../components/medicinestats";

export default function ProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [child, setChild] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editFormData, setEditFormData] = useState({ username: "", age: "", phone: "" });

  const [showDetails, setShowDetails] = useState(false);
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
      
        <section className="bg-white shadow rounded p-6">
        <MedicineStats childId={child.id} username={child.username}/>

          </section>

        {/* Health Reports */}
        <section className="bg-white shadow rounded p-6">
          <h3 className="text-xl font-semibold mb-4">Health Reports</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="bg-blue-50 p-4 rounded shadow text-center">
              <div className="font-bold text-blue-600">{healthReports.bloodPressure}</div>
              <div className="text-gray-700">Blood Pressure</div>
            </div>
            <div className="bg-purple-50 p-4 rounded shadow text-center">
              <div className="font-bold text-purple-600">{healthReports.cholesterol}</div>
              <div className="text-gray-700">Cholesterol</div>
            </div>
            <div className="bg-pink-50 p-4 rounded shadow text-center">
              <div className="font-bold text-pink-600">{healthReports.bloodSugar}</div>
              <div className="text-gray-700">Blood Sugar</div>
            </div>
          </div>
        </section>
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
