class AppValidators {
  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required hai';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Valid email daalo';
    return null;
  }
  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required hai';
    if (v.length < 6) return 'Min 6 characters chahiye';
    return null;
  }
  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Naam required hai';
    if (v.trim().length < 2) return 'Naam bahut chhota hai';
    return null;
  }
  static String? validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Title required hai';
    if (v.trim().length < 3) return 'Title bahut chhota hai';
    return null;
  }
  static String? validateConfirmPassword(String? v, String p) {
    if (v == null || v.isEmpty) return 'Password confirm karo';
    if (v != p) return 'Passwords match nahi kar rahe';
    return null;
  }
}
