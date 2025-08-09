import { useState, useEffect } from "react";
import { supabase } from "../supabase/supabase-client";
import { useNavigate, useLocation } from "react-router-dom";

export default function ResetPassword() {
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    // Extract the access_token from URL hash (#)
    const params = new URLSearchParams(location.hash.substring(1));
    const accessToken = params.get("access_token");

    if (!accessToken) {
      setMessage("Invalid or expired password reset link.");
    } else {
      // Set Supabase client auth token to authorize password update
      supabase.auth.setAuth(accessToken);
    }
  }, [location.hash]);

  const handleReset = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage("");

    const { error } = await supabase.auth.updateUser({ password: newPassword });

    setLoading(false);

    if (error) {
      setMessage("Error resetting password: " + error.message);
    } else {
      setMessage("Password successfully reset! Redirecting to login...");
      setTimeout(() => navigate("/login"), 3000); // Redirect after 3 seconds
    }
  };

  return (
    <div className="max-w-md mx-auto p-6 mt-10 bg-white rounded shadow">
      <h2 className="text-2xl font-semibold mb-4">Reset Password</h2>
      {message && <p className="mb-4">{message}</p>}

      {!message.includes("successfully") && (
        <form onSubmit={handleReset}>
          <label htmlFor="new-password" className="block mb-2 font-medium">
            Enter new password
          </label>
          <input
            id="new-password"
            type="password"
            required
            minLength={6}
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="w-full p-2 mb-4 border rounded"
          />
          <button
            type="submit"
            disabled={loading}
            className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 transition"
          >
            {loading ? "Resetting..." : "Reset Password"}
          </button>
        </form>
      )}
    </div>
  );
}
