

import { useState, useRef, useEffect } from "react";
import { FaUserCircle } from "react-icons/fa";
import { IoPersonAddSharp } from "react-icons/io5";
import { FaPills } from "react-icons/fa6";
import { supabase } from "../supabase/supabase-client"; //  supabase client
import { Link } from "react-router-dom";
import { useLocation } from "react-router-dom";
import { IoAdd } from "react-icons/io5";
import { GrClose } from "react-icons/gr";
import Swal from 'sweetalert2'
import { showError, showSuccess } from "../utils/alert"; // for my custom alerts


export default function Header({ onMemberAdded, onMedicineAdded }) {
  const [open, setOpen] = useState(false);
  const [showNewMemberModal, setShowNewMemberModal] = useState(false);
  const [username, setUsername] = useState("");
  const [phone,setPhone] =useState("")
  const [age, setAge] = useState("");
  const [childUsers, setChildUsers] = useState([]);
  const menuRef = useRef(null);


  const [showProfileModal, setShowProfileModal] = useState(false);
  const [profile, setProfile] = useState({ name: "", mobile: "" });
  const [loadingProfile, setLoadingProfile] = useState(false);
  const [passwords, setPasswords] = useState({ oldPassword: "", newPassword: "" });
  const [updating, setUpdating] = useState(false);
  const [error, setError] = useState(null);
  const [showPassword, setShowPassword] = useState(false);


  const openProfileModal = () => {
    setError("");
    setProfile(null);       //  null while loading
    setLoadingProfile(true); //  set loading BEFORE showing modal
    setShowProfileModal(true);
  };

  // Fetch profile on modal open
  // ------------modal showing mehod for profile start-----------------------
  useEffect(() => {
    if (!showProfileModal) return;
    let mounted = true;

    (async function fetchProfile() {
      try {
        openProfileModal()
        // keep loading already true from openProfileModal
        const { data: { user }, error: userError } = await supabase.auth.getUser();
        if (!mounted) return;

        if (userError || !user) {
          setError(userError?.message || "No user logged in");
          setLoadingProfile(false);
          return;
        }

        const { data, error } = await supabase
          .from("parent_profiles")
          .select("full_name, phone, email")
          .eq("id", user.id)
          .single();

        if (!mounted) return;

        if (error) {
          setError(error.message);
          setProfile({ name: "", mobile: "", email: "" });
        } else {
          setProfile({
            name: data?.full_name || "",
            mobile: data?.phone || "",
            email: data?.email || ""
          });
        }
      } catch (err) {
        if (mounted) setError(err.message || "Failed to fetch");
      } finally {
        if (mounted) setLoadingProfile(false);
      }
    })();

    return () => { mounted = false; };
  }, [showProfileModal]);
  // ------------modal showing mehod for profile end-----------------------


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
    // -----------method for fetching all child users---------------------
    fetchChildUsers();
    function handleClickOutside(e) {

      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);
  // -----------method for fetching all child users---------------------

  // -----------method for adding new child users---------------------

  // Inside your component:
  const [loading, setLoading] = useState(false);


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
      if (!phone.trim() || !/^\d{10}$/.test(phone.trim())) {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "Please enter a valid 10-digit phone number.",
          showConfirmButton: false,
          timer: 1000
        });
        return;
      }
      // Check if username already exists for this parent
      const { data: existing, error: checkError } = await supabase
        .from("child_users")
        .select("child_phone")
        .eq("parent_id", user.id)
        .eq("child_phone", phone.trim())
        .maybeSingle();

      if (checkError) throw checkError;

      if (existing) {
        Swal.fire({
          position: "top-end",
          icon: "warning",
          title: "This phone number is already assigned to another member",
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
            child_phone: phone.trim(), // new phone field
          },
        ])
        .select()
        .single();


      if (error) throw error;
      if (onMemberAdded) {
        onMemberAdded();  // Call the parent callback to refresh members
      }
      Swal.fire({
        position: "top-end",
        icon: "success",
        title: "New member added successfully!",
        showConfirmButton: false,
        timer: 1000
      });

      setUsername("");
      setAge("");
      setPhone(""); // clear phone field
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

  };
  // -----------method for adding new child users---------------------

  // -----------method for adding new medicine for child users---------------------

  const location = useLocation();
  const [isModalOpen, setIsModalOpen] = useState(false);
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
      // --- VALIDATIONS ---
      if (!formData.child_id) {
        showError("Please select a child.");
        setLoading(false);
        return;
      }

      if (!formData.name || formData.name.trim().length < 2) {
        showError("Medicine name must be at least 2 characters.");
        setLoading(false);
        return;
      }

      if (isNaN(formData.dosage) || Number(formData.dosage) <= 0) {
        showError("Dosage must be a valid number greater than 0.");
        setLoading(false);
        return;
      }

      if (isNaN(formData.total_quantity) || Number(formData.total_quantity) < 0) {
        showError("Total quantity must be a non-negative number.");
        setLoading(false);
        return;
      }

      if (isNaN(formData.refill_threshold) || Number(formData.refill_threshold) < 0) {
        showError("Refill threshold must be a non-negative number.");
        setLoading(false);
        return;
      }

      if (Number(formData.refill_threshold) > Number(formData.total_quantity)) {
        showError("Refill threshold cannot be greater than total quantity.");
        setLoading(false);
        return;
      }

      // --- DUPLICATE CHECK ---
      const { data: existingMed, error: checkError } = await supabase
        .from("medicine")
        .select("id")
        .eq("child_id", formData.child_id)
        .ilike("name", formData.name.trim()); // case-insensitive

      if (checkError) throw checkError;

      if (existingMed && existingMed.length > 0) {
        showError(`Medicine "${formData.name}" already exists for this child.`);
        setLoading(false);
        return;
      }

      // --- INSERT ---
      const { data, error } = await supabase
        .from("medicine")
        .insert([
          {
            child_id: formData.child_id,
            name: formData.name.trim(),
            dosage: Number(formData.dosage),
            expiry_date: formData.expiry_date,
            daily_intake_times: formData.daily_intake_times,
            total_quantity: Number(formData.total_quantity),
            quantity_left: Number(formData.total_quantity),
            refill_threshold: Number(formData.refill_threshold),
          }
        ])
        .select()
        .single();

      if (error) throw error;

      showSuccess(`New medicine - ${formData.name} added`);

      if (onMedicineAdded) onMedicineAdded(data);

      setFormData({
        child_id: "",
        name: "",
        dosage: "",
        expiry_date: "",
        daily_intake_times: [],
        total_quantity: "",
        quantity_left: "",
        refill_threshold: "",
      });

      setIsModalOpen(false);

    } catch (err) {
      console.error("Error adding medicine:", err.message);
      showError("Failed to add medicine");
    } finally {
      setLoading(false);
    }
  };
  // -----------method for adding new medicine for child users---------------------

  //-----------current session user logout-----------------
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
  //-----------current session user logout-----------------

  // ----------------for mobile menu dropsown-----------------------
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  // Close mobile menu on route change
  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);
  // ----------------for mobile menu dropsown-----------------------


  return (
    <>
      <header className="bg-green-600 shadow-lg fixed top-0 left-0 right-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-2 pt-2">

            {/* Logo */}
            <Link to="/" className="text-white font-bold text-2xl">
              MedRemind
            </Link>

            {/* Hamburger button - only on small screens */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden text-green-100 hover:text-white focus:outline-none"
              aria-label="Toggle menu"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d={
                    mobileMenuOpen
                      ? "M6 18L18 6M6 6l12 12" // X icon when open
                      : "M4 6h16M4 12h16M4 18h16" // hamburger icon when closed
                  }
                />
              </svg>
            </button>

            {/* Desktop nav */}
            <nav className="hidden md:flex space-x-6 items-center ">
              <button
                onClick={() => setShowNewMemberModal(true)}
                className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1   transition-colors duration-200 font-medium"
              >
                <IoPersonAddSharp size={18} />
                New Member
              </button>

              {location.pathname === "/medicinestock" ? (
                <button
                  onClick={() => setIsModalOpen(true)}
                  className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1 transition-colors duration-200 font-medium"
                >
                  <IoAdd size={18} color="white" />
                  Add Medicine
                </button>
              ) : (
                <Link
                  to="/medicinestock"
                  className="flex items-center gap-2 text-green-100 hover:text-white border border-green-100 rounded px-3 py-1 transition-colors duration-200 font-medium"
                >
                  <FaPills size={18} color="white" />
                  Medicine Stock
                </Link>
              )}

              {/* Profile dropdown */}
              <div className="relative pt-4 ">
                <button
                  onClick={() => setOpen(!open)}
                  className="text-green-100 hover:text-white transition-colors duration-200"
                >
                  <FaUserCircle size={28} />
                </button>
                {open && (
                  <div className="absolute right-0 mt-2 w-40 bg-white rounded-md shadow-lg py-2 z-50">
                    <button
                      onClick={() => {
                        setOpen(false);
                        setShowProfileModal(true);
                      }}
                      className="block w-full text-left px-4 py-2 hover:bg-gray-100 text-black-700"
                      style={{ color: "green" }}
                    >
                      Profile
                    </button>
                    <button
                      onClick={() => {
                        setOpen(false);
                        onLogoutClick();
                      }}
                      className="block w-full text-left px-4 py-2 hover:bg-gray-100 text-green-700"
                      style={{ color: "green" }}

                    >
                      Logout
                    </button>
                  </div>
                )}
              </div>
            </nav>
          </div>
        </div>

        {/* Mobile menu dropdown */}
        <div
          className={`md:hidden bg-green-700 overflow-hidden transition-max-height duration-300 ease-in-out  ${mobileMenuOpen ? "max-h-96" : "max-h-0"
            }`}
        >
          <nav className="flex flex-col px-4 pb-4 space-y-3 text-green-100 pt-4">
            <button
              onClick={() => {
                setShowNewMemberModal(true);
                setMobileMenuOpen(false);
              }}
              className="flex items-center gap-2 border border-green-100 rounded px-3 py-2 font-medium hover:bg-green-600"
            >
              <IoPersonAddSharp size={18} />
              New Member
            </button>

            {location.pathname === "/medicinestock" ? (
              <button
                onClick={() => {
                  setIsModalOpen(true);
                  setMobileMenuOpen(false);
                }}
                className="flex items-center gap-2 border border-green-100 rounded px-3 py-2 font-medium hover:bg-green-600"
              >
                <IoAdd size={18} />
                Add Medicine
              </button>
            ) : (
              <Link
                to="/medicinestock"
                onClick={() => setMobileMenuOpen(false)}
                className="flex items-center gap-2 border border-green-100 rounded px-3 py-2 font-medium hover:bg-green-600"
              >
                <FaPills size={18} />
                Medicine Stock
              </Link>
            )}
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                setShowProfileModal(true);
              }}
              className="flex items-center gap-2 border border-green-100 rounded px-3 py-2 font-medium hover:bg-green-600"
            >
              <FaUserCircle size={28} />
              Profile
            </button>
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                onLogoutClick();
              }}
              className="flex items-center gap-2 border border-green-100 rounded px-3 py-2 font-medium hover:bg-green-600"
            >
              Logout
            </button>
          </nav>
        </div>
      </header>

      {/* ----------add new child member modal form start----------------------- */}
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
                <label className="block mb-1 text-gray-700">Phone Number</label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  required
                  disabled={loading}
                  pattern="[0-9]{10}" // validates a 10-digit number, adjust as needed
                  className="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring focus:ring-green-300 disabled:bg-gray-100"
                  placeholder="Enter child phone number"
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
                    setPhone("");
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
      {/* ----------add new child member modal form end----------------------- */}

      {/* ----------add new medicine modal form start----------------------- */}

      {isModalOpen && (
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
                    onClick={() => {
                      setIsModalOpen(false)

                      setFormData({
                        child_id: "",
                        name: "",
                        dosage: "",
                        expiry_date: "",
                        daily_intake_times: [],
                        total_quantity: "",
                        quantity_left: "",
                        refill_threshold: "",
                      });
                    }}
                    className="px-4 py-2 rounded bg-gray-600 hover:bg-gray-800"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={loading}
                    className={`px-4 py-2 rounded bg-green-600 text-white hover:bg-green-700 flex items-center gap-2 ${loading ? "opacity-50 cursor-not-allowed" : ""}`}
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
      {/* ----------add new medicine modal form end----------------------- */}



      {/* ----------amodal form for profile display start----------------------- */}

      {showProfileModal && (
        <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50 p-4 overflow-auto ">
          <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-md  max-h-[90vh] overflow-y-auto relative">

            <div className="fixed inset-0 flex items-center justify-center backdrop-blur-sm bg-black/30 z-50 p-4 overflow-auto">
              <div
                className={`bg-white rounded-lg shadow-lg p-6 w-full max-w-md overflow-y-auto relative transition-all duration-300`}
                style={{
                  // minHeight: loadingProfile ? "0px" : "auto", // Small fixed height when loading
                  // maxHeight: "90vh"
                  height: "90vh"
                }}
              >
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

                {loadingProfile || profile === null ? (
                  <div className="h-[60vh] flex flex-col items-center justify-center">
                    <div className="animate-spin rounded-full h-20 w-20 border-t-5 border-green-600"></div>
                    <span className="mt-4 text-gray-700 font-medium">Loading Profile ...</span>
                  </div>
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
          </div>
        </div>

      )}
      {/* ----------amodal form for profile display end----------------------- */}

    </>
  );
}
