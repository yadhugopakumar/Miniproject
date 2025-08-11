// utils/alerts.js for custom alerts helper
import Swal from "sweetalert2";

export const showError = (message) => {
  Swal.fire({
    icon: "error",
    title: "Oops...",
    text: message,
    confirmButtonColor: "#d33"
  });
};

export const showSuccess = (message) => {
  Swal.fire({
    icon: "success",
    title: "Success",
    text: message,
    confirmButtonColor: "#3085d6"
  });
};
