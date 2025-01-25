//! This class contains all form validators.

class FormValidator {
// -------------------------------
// Method for validating full name
// -------------------------------

  static String? firstNameValidator(String? value) {
    // Check if the text field is empty
    if (value!.isEmpty) {
      return "Please enter a full name";
    }
    // Validate the first name
    else if (!RegExp(r"^[a-zA-Z0-9]").hasMatch(value)) {
      return "Enter a valid full name";
    }
    // Ensure the first name is no longer than 30 characters
    else if (RegExp(r"^.{30}").hasMatch(value)) {
      return "Full name must be no longer than 30 characters";
    }
    // Ensure the first name does not contain special characters
    else if (RegExp(r"^(?=.*[#?!@$%^&*-+()/':;])").hasMatch(value)) {
      return "Full name should not contain special characters";
    }
    // Return null if validation passes
    else {
      return null;
    }
  }

// ----------------------------
// Method for validating email
// ----------------------------

  static String? emailValidator(String? value) {
    // Check if the text field is empty
    if (value!.isEmpty) {
      return "Please enter an email";
    }
    // Validate the email format
    else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$").hasMatch(value)) {
      return "Enter a valid email";
    }
    // Return null if validation passes
    else {
      return null;
    }
  }

// ------------------------------
// Method for validating password
// ------------------------------

  static String? passwordValidator(String? value) {
    // Check if the text field is empty
    if (value!.isEmpty) {
      return "Please enter a password";
    }

    // Validate that the password has at least 8 characters
    else if (!RegExp(r'^.{8,}$').hasMatch(value)) {
      return "Password must be at least 8 characters long";
    }

    // Validate that the password contains at least 1 number
    else if (!RegExp(r'.*\d+.*').hasMatch(value)) {
      return "Password must contain at least 1 number";
    }

    // Validate that the password contains at least 1 lowercase letter
    else if (!RegExp(r'.*[a-z]+.*').hasMatch(value)) {
      return "Password must contain at least 1 lowercase letter";
    }

    // Validate that the password contains at least 1 uppercase letter
    else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least 1 uppercase letter";
    }

    // Validate that the password contains at least 1 special character
    else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain at least 1 special character";
    }

    // Return null if validation passes
    else {
      return null;
    }
  }
}
