import { useState } from "react";
import { supabase } from "../supabase/supabase-client";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");


  // password reset function it calls resetpassword component
  async function handleSubmit(e) {
    e.preventDefault();
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`
    });

    if (error) {
      setMessage("Error sending reset email: " + error.message);
    } else {
      setMessage("Password reset email sent! Check your inbox.");
    }
  }
  // password reset function it calls resetpassword component

  return (
    <form onSubmit={handleSubmit} className="max-w-md mx-auto p-8">
      <label htmlFor="email" className="block mb-2 font-bold">
        Enter your email to reset password
      </label>
      <input
        id="email"
        type="email"
        required
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        className="w-full p-2 border rounded mb-4"
      />
      <button type="submit" className="bg-green-600 text-white px-4 py-2 rounded">
        Send Reset Email
      </button>
      {message && <p className="mt-4">{message}</p>}
    </form>
  );
}
