
import { Link, useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { supabase } from "../supabase/supabase-client";
import Swal from "sweetalert2";

export default function ProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [child, setChild] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const [isEditing, setIsEditing] = useState(false);

  const [editFormData, setEditFormData] = useState({
    username: "",
    age: "",
  });


  // ------------------------function for loaing details of child start------------------------------
  useEffect(() => {
    async function fetchChild() {
      setLoading(true);
      setError(null);
      const { data, error } = await supabase
        .from("child_users")
        .select("*")
        .eq("id", id)
        .single();

      if (error) {
        setError("Failed to load child details");
      } else {
        setChild(data);
      }
      setLoading(false);
    }
    fetchChild();
  }, [id]);

  const handleEdit = () => {
    setEditFormData({
      username: child.username,
      age: child.age || "",
    });
    setIsEditing(true);
  };
  // ------------------------function for loading details of child end------------------------------

  // ------------------------function for editing details of child start------------------------------

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Update child
      const { error: updateError } = await supabase
        .from("child_users")
        .update({
          username: editFormData.username.trim(),
          age: editFormData.age ? parseInt(editFormData.age, 10) : null,
        })
        .eq("id", child.id);

      if (updateError) throw updateError;

      // Refetch updated data
      const { data: freshData, error: fetchError } = await supabase
        .from("child_users")
        .select("*")
        .eq("id", child.id)
        .single();

      if (fetchError) throw fetchError;

      setChild(freshData);

      Swal.fire({
        position: "top-end",
        icon: "success",
        title: "Data updated successfully",
        showConfirmButton: false,
        timer: 1000,
      });

      setIsEditing(false);
    } catch (err) {
      console.error(err);
      Swal.fire({
        position: "top-end",
        icon: "error",
        title: "Failed to update child user",
        showConfirmButton: false,
        timer: 1000,
      });
    } finally {
      setLoading(false);
    }
  };
  // ------------------------function for editing details of child end------------------------------
  // ------------------------function for deleting details of child start------------------------------

  async function handleDelete() {
    const result = await Swal.fire({
      title: "Are you sure?",
      text: "You won't be able to revert this!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, delete it!",
      cancelButtonText: "Cancel",
    });

    if (!result.isConfirmed) return;

    setDeleting(true);
    const { error } = await supabase.from("child_users").delete().eq("id", id);
    setDeleting(false);

    if (error) {
      Swal.fire({
        position: "top-end",
        icon: "error",
        title: "Failed to delete member: " + error.message,
        showConfirmButton: false,
        timer: 1500,
      });
    } else {
      Swal.fire({
        position: "top-end",
        icon: "success",
        title: "Member deleted successfully.",
        showConfirmButton: false,
        timer: 1500,
      });
      navigate("/");
    }
  }
  // ------------------------function for deleting details of child end------------------------------

  if (loading)
    return (
      <div className="grid place-items-center h-screen">
        <div className="flex flex-col items-center justify-center">
          <div className="animate-spin rounded-full h-14 w-14 border-t-4 border-green-600"></div>
          <span className="mt-4 text-gray-700 font-medium">
            Loading child details...
          </span>
        </div>
      </div>
    );

  if (error) return <div className="p-8 text-center text-red-600">{error}</div>;
  if (!child) return <div className="p-8 text-center">No child found.</div>;

  // Placeholder data for health tracker, replace with real data
  const missedMedicine = 2;
  const takenMedicine = 25;
  const healthReports = {
    bloodPressure: "120/80 mmHg",
    cholesterol: "180 mg/dL",
    bloodSugar: "90 mg/dL",
  };

  return (
    <div>
      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <Link to="/" className="text-white font-bold text-2xl">
              MedRemind
            </Link>
            <button
              onClick={() => navigate(-1)}
              className="text-white bg-green-700 hover:bg-green-800 px-3 py-1 rounded"
            >
              ← Back
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-3xl mx-auto p-6 bg-white shadow rounded mt-8">
        <section className="mb-10">
          <h2 className="text-2xl font-semibold mb-4">{child.username}</h2>
          <p className="mb-2">
            <strong>Age:</strong> {child.age ?? "N/A"}
          </p>

          <div className="mt-6 flex space-x-4">
            <button
              onClick={handleEdit}
              className="px-4 py-2 bg-yellow-400 hover:bg-yellow-500 text-white rounded shadow"
            >
              Edit
            </button>
            <button
              onClick={handleDelete}
              disabled={deleting}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded shadow disabled:opacity-50"
            >
              {deleting ? "Deleting..." : "Delete"}
            </button>
          </div>
        </section>

        <section className="bg-green-50 rounded-lg p-6">
          <h3 className="text-xl font-semibold mb-4">Health Tracker</h3>
          <div className="grid grid-cols-3 gap-6 mb-6 text-center">
            <div>
              <div className="text-lg font-bold text-red-600">{missedMedicine}</div>
              <div className="text-sm font-medium text-gray-700">Missed Medicine</div>
            </div>
            <div>
              <div className="text-lg font-bold text-green-600">{takenMedicine}</div>
              <div className="text-sm font-medium text-gray-700">Taken Medicine</div>
            </div>
            <div>
              <div className="text-lg font-bold text-yellow-500">1</div>
              <div className="text-sm font-medium text-gray-700">Late Medicine</div>
            </div>
          </div>

          <div className="space-y-3">
            <div>
              <strong>Blood Pressure:</strong> {healthReports.bloodPressure}
            </div>
            <div>
              <strong>Cholesterol:</strong> {healthReports.cholesterol}
            </div>
            <div>
              <strong>Blood Sugar:</strong> {healthReports.bloodSugar}
            </div>
          </div>
        </section>
      </div>


      {/* ------------------------child details editing form modal start------------------------------ */}

      {isEditing && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50">
          <form
            onSubmit={handleEditSubmit}
            className="space-y-4 p-6 border rounded bg-white max-w-sm w-full shadow-lg"
          >
            <div>
              <label className="block font-semibold mb-1">Name</label>
              <input
                type="text"
                name="username"
                value={editFormData.username}
                onChange={(e) =>
                  setEditFormData({ ...editFormData, username: e.target.value })
                }
                className="border rounded px-3 py-2 w-full"
                required
              />
            </div>
            <div>
              <label className="block font-semibold mb-1">Age</label>
              <input
                type="number"
                name="age"
                value={editFormData.age}
                onChange={(e) =>
                  setEditFormData({ ...editFormData, age: e.target.value })
                }
                min={1}
                max={100}
                className="border rounded px-3 py-2 w-full"
              />
            </div>
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => setIsEditing(false)}
                className="px-4 py-2 rounded bg-gray-800 hover:bg-gray-600 text-white"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded bg-yellow-500 hover:bg-yellow-600 text-white"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      )}
      {/* ------------------------child details editing form modal end------------------------------ */}

    </div>
  );
}
