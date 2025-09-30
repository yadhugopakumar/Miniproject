

import { useState, useEffect } from "react";
import { supabase } from "../supabase/supabase-client";
import Header from "../components/header";
import { FaEdit } from "react-icons/fa";
import { showError, showSuccess } from "../utils/alert";
import Swal from "sweetalert2";

export default function MedicineStockPage() {
  const [medicines, setMedicines] = useState([]);
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState("");
  const [loading, setLoading] = useState(true);

  const [showModal, setShowModal] = useState(false);
  const [selectedMed, setSelectedMed] = useState(null);

  const intakeTimesOptions = [
    "06:00 AM",
    "09:00 AM",
    "12:00 PM",
    "03:00 PM",
    "06:00 PM",
    "09:00 PM",
  ];

  // ----fetch medicines and users on startup-----------
  useEffect(() => {
    // FIX: Serialize the fetch calls to prevent the Navigator LockManager race condition
    async function initialFetch() {
      // Fetch users first
      await fetchUsers();
      // Then fetch medicines, potentially filtered
      await fetchMedicines();
    }
    initialFetch();

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);


  async function fetchMedicines(userId = "") {
    setLoading(true);

    const parentId = sessionStorage.getItem("user_id");
    if (!parentId) {
      console.error("Parent ID not found in sessionStorage.");
      setLoading(false);
      return;
    }

    let query = supabase
      .from("medicine")
      .select(`
        *,
        child_users(username)
      `)
      .eq("parent_id", parentId)
      .order("created_at", { ascending: false });


    if (userId) {
      query = query.eq("child_id", userId);
    }

    const { data, error } = await query;

    if (error) {
      console.error("Supabase Error fetching medicines:", error);
      showError("Failed to fetch medicines: " + error.message);
      setMedicines([]);
    } else {
      setMedicines(data || []);
    }

    setLoading(false);
  }


  async function fetchUsers() {
    const parentId = sessionStorage.getItem("user_id");
    if (!parentId) return;

    let { data, error } = await supabase
      .from("child_users")
      .select("id, username")
      .eq("parent_id", parentId)
      .order("username", { ascending: true });

    if (error) {
      console.error("Supabase Error fetching users:", error);
    } else {
      setUsers(data || []);
    }
  }
  // ----fetch medicines and users on startup-----------


  // ---------new medicine add,helper----------------
  function handleMedicineAdded(newMedicine) {
    setMedicines((prev) => [newMedicine, ...prev]);
  }
  // ---------new medicine add,helper----------------


  const openmodelforrefill = (id) => {
    console.log("Refill for:", id);
  };


  // ---------edit medicine helper----------------
  const editMedicine = (id) => {
    const med = medicines.find((m) => m.id === id);
    if (med) {
      // Retain the child_users object when editing
      const childUser = med.child_users;
      setSelectedMed({ ...med, child_users: childUser });
      setShowModal(true);
    }
  };
  // ---------new medicine helper----------------

  const closeModal = () => {
    setShowModal(false);
    setSelectedMed(null);
  };

  //  ----------------adding new medicine-----------------
  const saveMedicine = async () => {
    if (!selectedMed) return;

    // --- VALIDATIONS ---
    if (!selectedMed.name || selectedMed.name.trim().length < 2) {
      showError("Medicine name must be at least 2 characters.");
      return;
    }
    if (isNaN(selectedMed.dosage) || Number(selectedMed.dosage) <= 0) {
      showError("Dosage must be a valid number greater than 0.");
      return;
    }
    if (isNaN(selectedMed.total_quantity) || Number(selectedMed.total_quantity) < 0) {
      showError("Total quantity must be a non-negative number.");
      return;
    }
    if (isNaN(selectedMed.refill_threshold) || Number(selectedMed.refill_threshold) < 0) {
      showError("Refill threshold must be a non-negative number.");
      return;
    }
    if (Number(selectedMed.refill_threshold) > Number(selectedMed.total_quantity)) {
      showError("Refill threshold cannot be greater than total quantity.");
      return;
    }
    const parentId = sessionStorage.getItem("user_id");
    console.log(parentId);
    
    // --- SUPABASE UPDATE ---
    const { error } = await supabase
      .from("medicine")
      .update({
        name: selectedMed.name.trim(),
        dosage: Number(selectedMed.dosage),
        expiry_date: selectedMed.expiry_date,
        daily_intake_times: selectedMed.daily_intake_times,
        total_quantity: Number(selectedMed.total_quantity),
        refill_threshold: Number(selectedMed.refill_threshold),
        parent_id:parentId
      })
      .eq("id", selectedMed.id);

    if (!error) {
      // Retain the child_users object for display after update
      const updatedMed = {
        ...selectedMed,
        child_users: medicines.find(m => m.id === selectedMed.id)?.child_users
      };

      setMedicines((prev) =>
        prev.map((m) => (m.id === selectedMed.id ? updatedMed : m))
      );
      showSuccess("Medicine updated successfully!");
      closeModal();
    } else {
      showError(`Error updating medicine: ${error.message}`);
    }
  };
  //  ----------------adding new medicine-----------------

  //  ----------------delete medicine by id-----------------
  const deleteMedicine = async (id) => {
    const result = await Swal.fire({
      title: "Are you sure?",
      text: "This will permanently delete the medicine record.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, delete it!"
    });

    if (result.isConfirmed) {
      const { error } = await supabase.from("medicine").delete().eq("id", id);

      if (!error) {
        setMedicines((prev) => prev.filter((m) => m.id !== id));
        Swal.fire("Deleted!", "The medicine has been removed.", "success");
        closeModal();
      } else {
        showError("Failed to delete medicine");
      }
    }
  };
  //  ----------------delete medicine by id-----------------

  return (
    <main>
      <Header onMedicineAdded={handleMedicineAdded} />

      <div className="max-w-7xl mx-auto p-6 my-15">
        <h1 className="text-2xl font-bold mb-4">Medicine Stock Management</h1>

        {/* Filter by User */}
        <div className="mb-4">
          <select
            value={selectedUser}
            onChange={(e) => {
              setSelectedUser(e.target.value);
              fetchMedicines(e.target.value);
            }}
            className="border rounded px-3 py-2"
          >
            <option value="">All Users</option>
            {users.map((u) => (
              <option key={u.id} value={u.id}>
                {u.username}
              </option>
            ))}
          </select>
        </div>

        {/* -----------------Table schema--------------------*/}
        {loading ? (
          <div className="h-[60vh] flex flex-col items-center justify-center">
            <div className="animate-spin rounded-full h-20 w-20 border-4 border-t-4 border-green-600"></div>
            <span className="mt-4 text-gray-700 font-medium">Loading Medicines...</span>
          </div>
        ) : medicines.length === 0 ? (
          <div className="h-[60vh] flex flex-col items-center justify-center text-gray-600">
            <span className="text-lg font-medium">No medicine records found.</span>
            {selectedUser && (
              <span className="text-sm mt-2">Check 'All Users' or add a new medicine.</span>
            )}
          </div>
        ) : (
          <div className="overflow-x-auto custom-scroll">
            <table className="min-w-full border border-gray-300">
              <thead>
                <tr className="bg-green-600 text-white">
                  <th className="p-2 border">Name</th>
                  <th className="p-2 border">Dosage</th>
                  <th className="p-2 border">Expiry Date</th>
                  <th className="p-2 border">User</th>
                  <th className="p-2 border">Daily Times</th>
                  <th className="p-2 border">Available</th>
                  <th className="p-2 border">Status</th>

                </tr>
              </thead>
              <tbody>
                {medicines.map((med) => {
                  const quantityLeft = med.quantity_left !== undefined ? med.quantity_left : 0;
                  const refillThreshold = med.refill_threshold !== undefined ? med.refill_threshold : 0;
                  const totalQuantity = med.total_quantity !== undefined ? med.total_quantity : 0;

                  const isLow = quantityLeft <= refillThreshold;
                  return (
                    <tr key={med.id} className="hover:bg-gray-100" style={{ height: "max-content" }}>

                      <td className="px-1 text-center border h-full">
                        <div className="flex items-center justify-center w-full h-full group relative py-2">
                          <button
                            onClick={() => editMedicine(med.id)}
                            className="my-3 px-3 flex items-center justify-center text-blue-600 hover:text-blue-800 cursor-pointer w-full h-full"
                            style={{ color: "black", backgroundColor: "rgb(207, 236, 228)" }}

                          >
                            <FaEdit size={20} />
                            {/* Tooltip */}
                            <div className="absolute left-1/2 -translate-x-1/2 -top-3 bg-black text-white text-md px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none whitespace-nowrap">
                              Click to edit
                            </div>
                            <span className="ml-2">{med.name}</span>
                          </button>
                        </div>
                      </td>

                      <td className="px-1 text-center border">{med.dosage} Pill</td>
                      <td className="px-1 text-center border">{med.expiry_date || 'N/A'}</td>
                      <td className="px-1 text-center border">{med.child_users?.username}</td>
                      <td className="px-1 text-center border p-2" style={{ width: "170px", minWidth: "110px" }}>{med.daily_intake_times ? med.daily_intake_times.join(", ") : 'N/A'}</td>
                      <td className="px-1 text-center border">{quantityLeft}/{totalQuantity}</td>
                      <td
                        className={`text-center border font-semibold  ${isLow ? "text-red-600" : "text-green-600"
                          }`}

                      >
                        {isLow ? (
                          <div className="relative group w-full h-full ">
                            <button
                              onClick={() => openmodelforrefill(med.id)}
                              className="cursor-pointer w-full h-full bg-yellow-200 font-semibold py-8 hover:bg-yellow-600 hover:text-white-100"
                              style={{ color: "black" }}>
                              Refill
                            </button>

                            <div className="absolute left-1/2 -translate-x-1/2 -top-10 bg-black text-white text-sm px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none">
                              Click to refill the stock
                            </div>
                          </div>
                        ) : (
                          <span>Stock is fine</span>
                        )}

                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>

          </div>

        )}
        {/* -----------------Table schema--------------------*/}

      </div>


      {/* -----------------Edit Modal---------------------- */}
      {showModal && selectedMed && (
        <div className="fixed inset-0 backdrop-blur-sm bg-black/30 z-50 flex justify-center items-start pt-6 pb-4 overflow-y-auto">
          <div
            className="bg-white rounded-lg shadow-lg p-6 w-full max-w-lg relative"
            style={{ height: "fit-content", marginTop: "40px" }}
          >
            <h2 className="text-xl font-bold mb-4">Edit Medicine</h2>

            {/* --- CORRECTED CHILD SELECTOR --- */}
            <label className="block mb-2 font-medium">Assign to Child User</label>
            <select
              // Use the currently assigned child_id as the controlled value
              value={selectedMed.child_id}
              // Use a dedicated handler for updating the selectedMed state
              onChange={(e) => {
                // Ensure the new value is stored as the child_id
                setSelectedMed({ ...selectedMed, child_id: e.target.value });
              }}
              className="border rounded px-3 py-2 w-full mb-4"
            >
              {/* Optional: Add a disabled default option if no child is selected */}
              <option value="" disabled>Select a child</option>
              
              {/* Map through all users to create options */}
              {users.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.username}
                </option>
              ))}
            </select>
            {/* ------------------------------------- */}

            {/* Name */}
            <label className="block mb-2 font-medium">Name</label>
            <input
              type="text"
              value={selectedMed.name}
              onChange={(e) =>
                setSelectedMed({ ...selectedMed, name: e.target.value })
              }
              className="border rounded px-3 py-2 w-full mb-4"
            />

            {/* Dosage */}
            <label className="block mb-2 font-medium">Dosage</label>
            <input
              type="text"
              value={selectedMed.dosage}
              onChange={(e) =>
                setSelectedMed({ ...selectedMed, dosage: e.target.value })
              }
              className="border rounded px-3 py-2 w-full mb-4"
            />

            {/* Expiry Date */}
            <label className="block mb-2 font-medium">Expiry Date</label>
            <input
              type="date"
              value={selectedMed.expiry_date}
              onChange={(e) =>
                setSelectedMed({ ...selectedMed, expiry_date: e.target.value })
              }
              className="border rounded px-3 py-2 w-full mb-4"
            />

            {/* Daily Intake Times */}
            <label className="block mb-2 font-medium">Daily Intake Times</label>
            <div className="flex flex-wrap gap-3 mb-4">
              {intakeTimesOptions.map((time) => (
                <label
                  key={time}
                  className={`cursor-pointer px-3 py-1 rounded border ${selectedMed.daily_intake_times?.includes(time) // Added safe chaining ?.
                    ? "bg-green-600 text-white border-green-600"
                    : "border-gray-300 text-gray-700"
                    }`}
                >
                  <input
                    type="checkbox"
                    value={time}
                    checked={selectedMed.daily_intake_times?.includes(time)} // Added safe chaining ?.
                    onChange={() => {
                      const currentTimes = selectedMed.daily_intake_times || []; // Initialize if null
                      const updatedTimes = currentTimes.includes(time)
                        ? currentTimes.filter((t) => t !== time)
                        : [...currentTimes, time];
                      setSelectedMed({ ...selectedMed, daily_intake_times: updatedTimes });
                    }}
                    className="hidden"
                  />
                  {time}
                </label>
              ))}
            </div>

            {/* Total Quantity */}
            <label className="block mb-2 font-medium">Total Quantity</label>
            <input
              type="number"
              value={selectedMed.total_quantity}
              onChange={(e) =>
                setSelectedMed({ ...selectedMed, total_quantity: e.target.value })
              }
              className="border rounded px-3 py-2 w-full mb-4"
            />

            {/* Refill Threshold */}
            <label className="block mb-2 font-medium">Refill Threshold</label>
            <input
              type="number"
              value={selectedMed.refill_threshold}
              onChange={(e) =>
                setSelectedMed({ ...selectedMed, refill_threshold: e.target.value })
              }
              className="border rounded px-3 py-2 w-full mb-4"
            />

            {/* Action Buttons */}
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={closeModal}
                className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-500"
              >
                Cancel
              </button>
              <button
                onClick={saveMedicine}
                className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
              >
                Save
              </button>
            </div>

            <hr className="my-4" />

            {/* Delete Button */}
            <div className="flex justify-center">
              <button
                onClick={() => deleteMedicine(selectedMed.id)}
                className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 w-full"
              >
                Delete
              </button>
            </div>

          </div>
        </div>
      )}
      {/* -----------------Edit Modal---------------------- */}


    </main>
  );
}