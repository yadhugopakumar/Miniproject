
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
    fetchUsers();
    fetchMedicines();
  }, []);

  async function fetchMedicines(userId = "") {
    setLoading(true);
    let query = supabase
      .from("medicine")
      .select(`
        *,
        child_users(username)
      `)
      .order("created_at", { ascending: false });

    if (userId) {
      query = query.eq("child_id", userId);
    }

    let { data, error } = await query;
    if (!error) setMedicines(data);
    setLoading(false);
  }

  async function fetchUsers() {
    let { data, error } = await supabase
      .from("child_users")
      .select("id, username");
    if (!error) setUsers(data);
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
      setSelectedMed({ ...med });
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

    // --- SUPABASE UPDATE ---
    const { data, error } = await supabase
      .from("medicine")
      .update({
        name: selectedMed.name.trim(),
        dosage: Number(selectedMed.dosage),
        expiry_date: selectedMed.expiry_date,
        daily_intake_times: selectedMed.daily_intake_times,
        total_quantity: Number(selectedMed.total_quantity),
        refill_threshold: Number(selectedMed.refill_threshold)
      })
      .eq("id", selectedMed.id);

    if (!error) {
      setMedicines((prev) =>
        prev.map((m) => (m.id === selectedMed.id ? selectedMed : m))
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
            <div className="animate-spin rounded-full h-20 w-20 border-t-5 border-green-600"></div>
            <span className="mt-4 text-gray-700 font-medium">Loading Medicines ...</span>
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
                  const isLow = med.quantity_left <= med.refill_threshold;
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
                      <td className="px-1 text-center border">{med.expiry_date}</td>
                      <td className="px-1 text-center border">{med.child_users?.username}</td>
                      <td className="px-1 text-center border p-2" style={{ width: "170px", minWidth: "110px" }}>{med.daily_intake_times.join(", ")}</td>
                      <td className="px-1 text-center border">{med.quantity_left}/{med.total_quantity}</td>
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
                  className={`cursor-pointer px-3 py-1 rounded border ${selectedMed.daily_intake_times.includes(time)
                    ? "bg-green-600 text-white border-green-600"
                    : "border-gray-300 text-gray-700"
                    }`}
                >
                  <input
                    type="checkbox"
                    value={time}
                    checked={selectedMed.daily_intake_times.includes(time)}
                    onChange={() => {
                      const updatedTimes = selectedMed.daily_intake_times.includes(time)
                        ? selectedMed.daily_intake_times.filter((t) => t !== time)
                        : [...selectedMed.daily_intake_times, time];
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

