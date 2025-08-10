import { useState, useEffect } from "react";
import { supabase } from "../supabase/supabase-client";
import Header from "../components/header";

export default function MedicineStockPage() {
  const [medicines, setMedicines] = useState([]);
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
    fetchMedicines();
  }, []);

  async function fetchUsers() {
    let { data, error } = await supabase
      .from("child_users")
      .select("id, username");
    if (!error) setUsers(data);
  }

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

  return (
    <main>
    <Header/>
    <div className="max-w-7xl mx-auto p-6">
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

      {/* Table */}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <thead>
              <tr className="bg-green-600 text-white">
                <th className="p-2 border">Name</th>
                <th className="p-2 border">Dosage</th>
                <th className="p-2 border">Expiry Date</th>
                <th className="p-2 border">User</th>
                <th className="p-2 border">Daily Times</th>
                <th className="p-2 border">Quantity Left</th>
                <th className="p-2 border">Refill Status</th>
              </tr>
            </thead>
            <tbody>
              {medicines.map((med) => {
                const isLow = med.quantity_left <= med.refill_threshold;
                return (
                  <tr key={med.id} className="hover:bg-gray-100">
                    <td className="p-2 border">{med.name}</td>
                    <td className="p-2 border">{med.dosage}</td>
                    <td className="p-2 border">{med.expiry_date}</td>
                    <td className="p-2 border">{med.child_users?.username}</td>
                    <td className="p-2 border">{med.daily_intake_times.join(", ")}</td>
                    <td className="p-2 border">{med.quantity_left}/{med.total_quantity}</td>
                    <td
                      className={`p-2 border font-semibold ${
                        isLow ? "text-red-600" : "text-green-600"
                      }`}
                    >
                      {isLow ? "Low" : "OK"}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
    </main>
  );
}
