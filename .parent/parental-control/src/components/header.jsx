import { useState, useRef, useEffect } from "react";
import { FaUserCircle } from "react-icons/fa";
import { IoPersonAddSharp } from "react-icons/io5";
import { FaPills } from "react-icons/fa6";
import { supabase } from "../supabase/supabase-client"; // your supabase client
import { Link } from "react-router-dom";
import { useLocation } from "react-router-dom";
import { IoAdd } from "react-icons/io5";
import { GrClose } from "react-icons/gr";
import Swal from 'sweetalert2'


export default function Header() {
  const [open, setOpen] = useState(false);
  const [showNewMemberModal, setShowNewMemberModal] = useState(false);
  const [username, setUsername] = useState("");
  const [age, setAge] = useState(0);
  const [childUsers, setChildUsers] = useState([]);
  const menuRef = useRef(null);


  const [showProfileModal, setShowProfileModal] = useState(false);
  const [profile, setProfile] = useState({ name: "", mobile: "" });
  const [loadingProfile, setLoadingProfile] = useState(false);
  const [passwords, setPasswords] = useState({ oldPassword: "", newPassword: "" });
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState(null);
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  // Fetch profile on modal open
  useEffect(() => {
    async function fetchProfile() {
      setLoadingProfile(true);

      // Get user from supabase v2+
      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser();

      if (userError || !user) {
        setError(userError?.message || "No user logged in");
        setLoadingProfile(false);
        return;
      }

      // Now fetch profile info from your profiles table (adjust name as needed)
      const { data, error } = await supabase
        .from("parent_profiles")
        .select("full_name, phone,email")
        .eq("id", user.id)
        .single();

      if (error) {
        setError(error.message);
      } else if (data) {
        setProfile({ name: data.full_name || "", mobile: data.phone || "", email: data.email || "" });
      } else {
        setProfile({ name: "", mobile: "" });
      }

      setLoadingProfile(false);
    }

    if (showProfileModal) {
      fetchProfile();
    }
  }, [showProfileModal]);

  // Handle input change for profile form
  function handleProfileChange(e) {
    setProfile({ ...profile, [e.target.name]: e.target.value });
  }

  // Handle password input change
  function handlePasswordChange(e) {
    setPasswords({ ...passwords, [e.target.name]: e.target.value });
    console.log(passwords);

  }

  // Update profile handler
  async function updateProfile(profileData) {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      console.error("No user logged in or error fetching user:", userError);
      return;
    }
    const updateData = {
      full_name: profile.name,
      phone: profile.mobile,
    };

    const { error } = await supabase
      .from("parent_profiles")
      .update(updateData)
      .eq("id", user.id);



    if (error) {
      console.error("Error updating profile:", error.message);
    } else {
      Swal.fire("Profile Updated");
      setShowProfileModal(false)
    }
  }

  // Change password handler
  async function changePassword() {
    setUpdating(true);
    setError(null);

    try {
      const { data, error } = await supabase.auth.updateUser({
        password: passwords.oldPassword,
        newPassword: passwords.newPassword,
      });

      if (error) {
        setError(error.message);
        console.error("Error updating password:", error.message);
      } else {
        Swal.fire("Password updated successfully!");
        setPasswords({ oldPassword: "", newPassword: "" });
      }
    } catch (err) {
      setError(err.message);
      console.error("Unexpected error:", err.message);
    }


    setUpdating(false);
  }

  // Delete account handler (confirm first)
  async function deleteAccount() {
    if (!confirm("Are you sure you want to delete your account? This action is irreversible.")) {
      return;
    }
    setUpdating(true);
    setError(null);
    const user = supabase.auth.user();
    if (!user) {
      setError("User not logged in");
      setUpdating(false);
      return;
    }

    // Supabase doesn't provide direct account deletion via client SDK yet;
    // You may need a server function or use REST API with admin rights.
    // For demo, just sign out:
    alert("Account deletion needs backend support. Signing out for now.");
    await supabase.auth.signOut();
    setUpdating(false);
  }



  // Close menu on outside click
  useEffect(() => {

    async function fetchChildUsers() {
      const { data, error } = await supabase
        .from("child_users")
        .select("id, username")
        .order("username", { ascending: true });

      if (error) {
        console.error("Error fetching child users:", error.message);
      } else {
        setChildUsers(data);
      }
    }

    fetchChildUsers();
    function handleClickOutside(e) {

      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);


  // Inside your component:
  const [loading, setLoading] = useState(false);

  // Handle adding new child user
  // const handleAddChildUser = async (e) => {
  //   e.preventDefault();
  //   setLoading(true);
  //   try {
  //     const { data: { user } } = await supabase.auth.getUser();
  //     if (!user) {
  //       alert("You must be logged in to add a new member.");
  //       return;
  //     }

  //     const { error } = await supabase.from("child_users").insert([
  //       {
  //         parent_id: user.id,
  //         username: username.trim(),
  //         age: parseInt(age, 10),
  //       },
  //     ]);

  //     if (error) throw error;

  //     alert("New member added successfully!");
  //     setUsername("");
  //     setShowNewMemberModal(false);
  //   } catch (err) {
  //     console.error(err);
  //     alert("Failed to add new member.");
  //   } finally {
  //     setLoading(false);
  //   }
  // };

  const handleAddChildUser = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        Swal.fire({
          position: "top-end",
          icon: "error",
          title: "You must be logged in to add a new member.",
          showConfirmButton: false,
          timer: 1000
        });
        return;
      }

      // Name validation
      if (!username.trim()) {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "Name cannot be empty.",
          showConfirmButton: false,
          timer: 1000
        });
        return;
      }

      // Age validation
      const parsedAge = parseInt(age, 10);
      if (isNaN(parsedAge) || parsedAge < 1 || parsedAge > 100) {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "Please enter a valid age.",
          showConfirmButton: false,
          timer: 1000
        });
        return;
      }

      // Check if username already exists for this parent
      const { data: existing, error: checkError } = await supabase
        .from("child_users")
        .select("username")
        .eq("parent_id", user.id)
        .eq("username", username.trim())
        .maybeSingle();

      if (checkError) throw checkError;

      if (existing) {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "This name already exists.",
          showConfirmButton: false,
          timer: 1000
        });
        return;
      }

      // Insert new child and get inserted record
      const { data: inserted, error } = await supabase
        .from("child_users")
        .insert([
          {
            parent_id: user.id,
            username: username.trim(),
            age: parsedAge,
          },
        ])
        .select()
        .single();

      if (error) throw error;

      // Update UI immediately without waiting for a refetch
      setChildUsers((prev) => [...prev, inserted]);

      Swal.fire({
        position: "top-end",
        icon: "success",
        title: "New member added successfully!",
        showConfirmButton: false,
        timer: 1000
      });

      setUsername("");
      setAge("");
      setShowNewMemberModal(false);

    } catch (err) {
      console.error(err);
      Swal.fire({
        position: "top-end",
        icon: "error",
        title: "Failed to add new member.",
        showConfirmButton: false,
        timer: 1000
      });
    } finally {
      setLoading(false);
    }
    console.log("haai");

  };



  const location = useLocation();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [medloading, setMedLoading] = useState(false);
  const intakeTimesOptions = [
    "06:00 AM",
    "09:00 AM",
    "12:00 PM",
    "03:00 PM",
    "06:00 PM",
    "09:00 PM",
  ];

  const [formData, setFormData] = useState({
    child_id: "",
    name: "",
    dosage: "",
    expiry_date: "",
    daily_intake_times: "",
    total_quantity: "",
    quantity_left: "",
    refill_threshold: ""
  });

  const handleChange = (e) => {
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };
  // Handle checkbox toggle for intake times
  const handleIntakeTimeToggle = (time) => {
    setFormData((prev) => {
      const currentTimes = prev.daily_intake_times;
      if (currentTimes.includes(time)) {
        // Remove if already selected
        return {
          ...prev,
          daily_intake_times: currentTimes.filter((t) => t !== time),
        };
      } else {
        // Add new time
        return {
          ...prev,
          daily_intake_times: [...currentTimes, time],
        };
      }
    });
  };
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const { error } = await supabase.from("medicine").insert([
        {
          child_id: formData.child_id,
          name: formData.name,
          dosage: formData.dosage,
          expiry_date: formData.expiry_date,
          daily_intake_times: formData.daily_intake_times,
          total_quantity: parseInt(formData.total_quantity, 10),
          quantity_left: parseInt(formData.quantity_left, 10),
          refill_threshold: parseInt(formData.refill_threshold, 10)
        }
      ]);

      if (error) throw error;

      setFormData({
        child_id: "",
        name: "",
        dosage: "",
        expiry_date: "",
        daily_intake_times: "",
        total_quantity: "",
        quantity_left: "",
        refill_threshold: ""
      });
      setIsModalOpen(false);
    } catch (err) {
      console.error("Error adding medicine:", err.message);
    } finally {
      setMedLoading(false);
    }
  };

  const onLogoutClick = () => {
    Swal.fire({
      title: "Logout Confirmation",
      text: "Are you sure you want to log out?",
      icon: "question",
      showCancelButton: true,
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#aaa",
      confirmButtonText: "Yes, log me out",
      cancelButtonText: "Cancel"
    }).then(async (result) => {
      if (result.isConfirmed) {
        await supabase.auth.signOut();
        Swal.fire({
          title: "Logged out",
          text: "You have been successfully logged out.",
          icon: "success",
          timer: 1500,
          showConfirmButton: false
        });
        navigate("/login"); // Redirect to login
      }
    });

  }

  return (
    <>
      <header className="bg-green-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <Link to="/">
              <h1 className="text-2xl font-bold text-white">MedRemind</h1>
            </Link>
            <nav className="hidden md:flex space-x-6 items-center">
              <button
                onClick={() => setShowNewMemberModal(true)}
                className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1 transition-colors duration-200 font-medium"
              >
                <IoPersonAddSharp size={18} />
                New Member
              </button>
              {
                location.pathname === "/medicinestock" ? (<button
                  onClick={() => setIsModalOpen(true)}
                  className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1 transition-colors duration-200 font-medium"
                >
                  <IoAdd size={18} color="white" />
                  Add Medicine
                </button>) : (
                  <Link
                    to="/medicinestock"
                    className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1 transition-colors duration-200 font-medium"
                  >
                    <FaPills size={18} color="white" />
                    Medicine Stock
                  </Link>)


              }


              {/* Profile Dropdown */}
              <div className="relative" ref={menuRef}>
                <button
                  onClick={() => setOpen(!open)}
                  className="text-green-100 hover:text-white transition-colors duration-200"
                >
                  <FaUserCircle size={28} />
                </button>

                {open && (
                  <div className="absolute right-0 mt-2 w-40 bg-white rounded-md shadow-lg py-2 z-50">
                    <button onClick={() => {
                      setOpen(false);
                      setShowProfileModal(true);
                    }}
                      className="block w-full text-left px-4 py-2 hover:bg-gray-100"
                      style={{ color: "green", backgroundColor: "transparent" }}
                    >
                      Profile
                    </button>
                    <button
                      onClick={() => {
                        setOpen(false);
                        onLogoutClick();
                      }}
                      className="block w-full text-left px-4 py-2 hover:bg-gray-100"
                      style={{ color: "green", backgroundColor: "transparent" }}
                    >
                      Logout
                    </button>
                  </div>
                )}
              </div>
            </nav>
          </div>
        </div>
      </header >

      {showNewMemberModal && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50">
          <div className="bg-white rounded-lg p-6 w-96 shadow-lg">
            <h2 className="text-lg font-semibold mb-4">Add New Member</h2>
            <form onSubmit={handleAddChildUser}>
              <div className="mb-4">
                <label className="block mb-1 text-gray-700">Username</label>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                  disabled={loading}
                  className="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring focus:ring-green-300 disabled:bg-gray-100"
                  placeholder="Enter member name"
                />
              </div>
              <div className="mb-4">
                <label className="block mb-1 text-gray-700">Age</label>
                <input
                  type="number"
                  value={age}
                  onChange={(e) => setAge(e.target.value)}
                  required
                  min="0"
                  disabled={loading}
                  className="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring focus:ring-green-300 disabled:bg-gray-100"
                  placeholder="Enter member age"
                />
              </div>

              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setShowNewMemberModal(false);
                    setAge("");
                    setUsername("");
                  }}
                  disabled={loading}
                  className="px-4 py-2 bg-gray-600 rounded hover:bg-gray-400 disabled:opacity-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 flex items-center gap-2"
                >
                  {loading && (
                    <svg
                      className="animate-spin h-4 w-4 text-white"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8v4l3-3-3-3v4a8 8 0 00-8 8h4z"
                      ></path>
                    </svg>
                  )}
                  {loading ? "Saving..." : "Add Member"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )
      }

      {/* add medicine modalform */}
      {isModalOpen && (
        // <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-lg max-h-[100vh] overflow-y-auto z-50">

        //  <div className="fixed overflow-y-auto inset-0 backdrop-blur-sm bg-black/30 z-50 flex justify-center items-center " > 
        <div className="fixed inset-0 overflow-y-auto backdrop-blur-sm bg-black/30 z-50 flex justify-center pt-2 pb-2 max-h-[100vh]">
          <div className="bg-white rounded-lg shadow-lg w-full max-w-lg max-h-[100vh] overflow-y-auto">
            <div className="bg-green-50 rounded-lg shadow-lg p-6 w-full max-w-lg" >
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold mb-4">Add New Medicine</h2>

                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded bg-gray-100 text-black hover:bg-red-200 "

                >
                  <GrClose style={{ color: "black" }} />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-3">
                {/* Child User */}
                <div>
                  <label htmlFor="child_id" className="block font-medium mb-1">
                    Select Child User
                  </label>
                  <select
                    name="child_id"
                    value={formData.child_id}
                    onChange={handleChange}
                    required
                    className="border p-2 w-full rounded"
                  >
                    <option value="">Select Child</option>
                    {childUsers.map((child) => (
                      <option key={child.id} value={child.id}>
                        {child.username}
                      </option>
                    ))}
                  </select>
                </div>
                {/* Medicine Name */}
                <div>
                  <label htmlFor="name" className="block font-medium mb-1">
                    Medicine Name
                  </label>
                  <input
                    id="name"
                    type="text"
                    name="name"
                    placeholder="Medicine Name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>

                {/* Dosage */}
                <div>
                  <label htmlFor="dosage" className="block font-medium mb-1">
                    Dosage
                  </label>
                  <input
                    id="dosage"
                    type="text"
                    name="dosage"
                    placeholder="Dosage (e.g. 1 pill)"
                    value={formData.dosage}
                    onChange={handleChange}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>

                {/* Expiry Date */}
                <div>
                  <label htmlFor="expiry_date" className="block font-medium mb-1">
                    Expiry Date
                  </label>
                  <input
                    id="expiry_date"
                    type="date"
                    name="expiry_date"
                    value={formData.expiry_date}
                    onChange={handleChange}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>

                {/* Daily Intake Times */}
                <div>
                  <label className="block font-medium mb-1">
                    Daily Intake Times
                  </label>
                  <div className="flex flex-wrap gap-3">
                    {intakeTimesOptions.map((time) => (
                      <label
                        key={time}
                        className={`cursor-pointer px-3 py-1 rounded border ${formData.daily_intake_times.includes(time)
                          ? "bg-green-600 text-white border-green-600"
                          : "border-gray-300 text-gray-700"
                          }`}
                      >
                        <input
                          type="checkbox"
                          value={time}
                          checked={formData.daily_intake_times.includes(time)}
                          onChange={() => handleIntakeTimeToggle(time)}
                          className="hidden"
                        />
                        {time}
                      </label>
                    ))}
                  </div>
                </div>

                {/* Total Quantity */}
                <div>
                  <label htmlFor="total_quantity" className="block font-medium mb-1">
                    Total Quantity
                  </label>
                  <input
                    id="total_quantity"
                    type="number"
                    name="total_quantity"
                    placeholder="Total Quantity"
                    value={formData.total_quantity}
                    onChange={handleChange}
                    min={0}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>

                {/* Quantity Left */}
                <div>
                  <label htmlFor="quantity_left" className="block font-medium mb-1">
                    Quantity Left
                  </label>
                  <input
                    id="quantity_left"
                    type="number"
                    name="quantity_left"
                    placeholder="Quantity Left"
                    value={formData.quantity_left}
                    onChange={handleChange}
                    min={0}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>

                {/* Refill Threshold */}
                <div>
                  <label htmlFor="refill_threshold" className="block font-medium mb-1">
                    Refill Threshold
                  </label>
                  <input
                    id="refill_threshold"
                    type="number"
                    name="refill_threshold"
                    placeholder="Refill Threshold"
                    value={formData.refill_threshold}
                    onChange={handleChange}
                    min={0}
                    required
                    className="border p-2 w-full rounded"
                  />
                </div>


                <div className="flex justify-end gap-3 mt-4">
                  <button
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="px-4 py-2 rounded bg-gray-600 hover:bg-gray-800"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={medloading}
                    className="px-4 py-2 rounded bg-green-600 text-white hover:bg-green-700 flex items-center gap-2"
                  >
                    {loading && (
                      <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full"></span>
                    )}
                    Save
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}


      {/* Profile Modal */}
      {showProfileModal && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50 p-4 overflow-auto">
          <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-md max-h-[90vh] overflow-y-auto relative">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold mb-4">Profile Details</h2>


              <button
                type="button"
                onClick={() => setShowProfileModal(false)}
                className="px-4 py-2 rounded bg-gray-100 text-black hover:bg-red-200 "

              >
                <GrClose style={{ color: "black" }} />
              </button>
            </div>
            {loadingProfile ? (
              <p>Loading...</p>
            ) : (
              <>
                {error && <p className="text-red-600 mb-4">{error}</p>}
                <div className="mb-4">
                  <label className="block mb-1 font-medium">User Email</label>
                  <div className="w-full bg-gray-200 px-3 py-2">{profile.email}</div>
                </div>
                <div className="mb-4">
                  <label className="block mb-1 font-medium">Name</label>
                  <input
                    type="text"
                    name="name"
                    value={profile.name}
                    onChange={handleProfileChange}
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
                <div className="mb-4">
                  <label className="block mb-1 font-medium">Mobile</label>
                  <input
                    type="tel"
                    name="mobile"
                    value={profile.mobile}
                    onChange={handleProfileChange}
                    className="w-full border rounded px-3 py-2"
                  />
                </div>
                <button
                  onClick={updateProfile}
                  disabled={updating}
                  className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded mb-6"
                >
                  {updating ? "Updating..." : "Update Profile"}
                </button>

                <hr className="my-6" />

                <h3 className="text-lg font-semibold mb-3">Change Password</h3>
                <div className="mb-4">
                  <label className="block mb-1 font-medium">New Password</label>
                  {/* <input
                    type="password"
                    name="newPassword"
                    value={passwords.newPassword}
                    onChange={handlePasswordChange}
                    className="w-full border rounded px-3 py-2"
                  /> */}
                  <input
                    type={showPassword ? "text" : "password"}
                    value={passwords.oldPassword}
                    onChange={(e) => setPasswords({ ...passwords, oldPassword: e.target.value })}
                    placeholder="Enter your password"
                    className="border p-2 rounded w-full"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-2 top-2 text-sm text-gray-600"
                  >
                    {showPassword ? "Hide" : "Show"}
                  </button>
                </div>
                <button
                  onClick={changePassword}
                  disabled={updating}
                  className="bg-yellow-500 hover:bg-yellow-600 text-white px-4 py-2 rounded mb-6"
                >
                  {updating ? "Updating..." : "Change Password"}
                </button>


              </>
            )}

            <button
              onClick={() => setShowProfileModal(!showProfileModal)}
              className="absolute top-2 right-2 text-gray-600 hover:text-gray-900 font-bold text-xl"
              aria-label="Close profile modal"
            >
              &times;
            </button>
          </div>
        </div>
      )}
    </>
  );
}
