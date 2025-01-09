//! This class holds all form validators.

class FormValidator {
// -------------------------------
// Method for validating Full name
// -------------------------------

  static String? firstNameValidator(String? value) {
    // If the text field is empty
    if (value!.isEmpty) {
      return "Please enter a Full name";
    }
    // For first name validation
    else if (!RegExp(r"^[a-zA-Z0-9]").hasMatch(value)) {
      return "Enter a correct Full name";
    }
    // First name must be no longer than 15 characters
    else if (RegExp(r"^.{30}").hasMatch(value)) {
      return "Full name must be no longer than 30 characters";
    }
    // First name should not contain special characters
    else if (RegExp(r"^(?=.*[#?!@$%^&*-+()/':;])").hasMatch(value)) {
      return "Full name should not contain special characters";
    }
    // Else return nothing
    else {
      return null;
    }
  }

// ----------------------------
// Method for validating email
// ----------------------------

  static String? emailValidator(String? value) {
    // If the text field is empty
    if (value!.isEmpty) {
      return "Please enter an email";
    }
    // RegExp for email validation
    else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$").hasMatch(value)) {
      return "Enter a correct email";
    }
    // Else return nothing
    else {
      return null;
    }
  }

// ------------------------------
// Method for validating password
// ------------------------------

  static String? passwordValidator(String? value) {
    // If the text field is empty
    if (value!.isEmpty) {
      return "Please enter a password";
    }

    // validating atleast 8 chartors.
    else if (!RegExp(r'^.{8,}$').hasMatch(value)) {
      return "Password required at least 8 characters";
    }

    // validating at lest 1 number in password.
    else if (!RegExp(r'.*\d+.*').hasMatch(value)) {
      return "Password required at least 1 number";
    }

    // validating at lest 1 lowercase in password.
    else if (!RegExp(r'.*[a-z]+.*').hasMatch(value)) {
      return "Password required at least 1 lowercase character";
    }

    // validating at lest 1 uppercase in password.
    else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password required at least 1 uppercase character";
    }

    // validating at lest one special charctors in password.
    else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password required at least 1 sepcial character";
    }

    // Else return nothing
    else {
      return null;
    }
  }
}
