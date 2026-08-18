import 'package:admivida/common/constants/app_texts.dart';

class ValidatorsUtil {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyEmailError;
    }

    if (!EmailValidator.validate(value)) {
      return AppTexts.invalidEmailError;
    }
    return null;
  }

  /// Validates that the password meets enterprise-grade security standards.
  /// Requires: Min 8 characters, 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character.
  static String? validatePassword(String? value) {
    // Check if the field is completely empty
    if (value == null || value.isEmpty) {
      return AppTexts.emptyPasswordError;
    }

    // Check minimum length boundary
    if (value.length < 8) {
      return AppTexts.shortPasswordError;
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return AppTexts.uppercasePasswordError; // E.g., "Password must contain at least one uppercase letter"
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return AppTexts.lowercasePasswordError; // E.g., "Password must contain at least one lowercase letter"
    }

    // Check for at least one numeric digit
    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
      return AppTexts.numberPasswordError; // E.g., "Password must contain at least one number"
    }

    // Check for at least one special character (e.g., !@#$&*~-)
    if (!RegExp(r'(?=.*[!@#\$&*~`()_\-+={[}\]|:;"`<>,.?\/])').hasMatch(value)) {
      return AppTexts.specialCharPasswordError; // E.g., "Password must contain at least one special character"
    }

    return null; // Password is fully secure and valid
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyUsernameError;
    }
    if (value.length < 3) {
      return AppTexts.shortUsernameError;
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyNameError;
    }
    if (value.length < 3) {
      return AppTexts.shortNameError;
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyLastNameError;
    }
    if (value.length < 3) {
      return AppTexts.shortLastNameError;
    }
    return null;
  }

  static String? validatePhoneCode(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyPhoneCodeError;
    }
    if (!RegExp(r'^\+\d{1,3}$').hasMatch(value)) {
      return AppTexts.invalidPhoneCodeError;
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyPhoneError;
    }
    if (!PhoneValidator.validate(value)) {
      return AppTexts.invalidPhoneError;
    }

    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppTexts.emptyEmailOrPhoneError;
    }

    final trimmedValue = value.trim();

    // Si contiene un '@' o letras, asumimos que intenta ingresar un email
    final isEmailFormat = trimmedValue.contains('@') || RegExp(r'[a-zA-R]').hasMatch(trimmedValue);

    if (isEmailFormat) {
      if (!EmailValidator.validate(trimmedValue)) {
        return AppTexts.invalidEmailError;
      }
    } else {
      final cleanPhone = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      if (!PhoneValidator.validate(cleanPhone)) {
        return AppTexts.invalidPhoneError;
      }
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String text) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyConfirmPasswordError;
    }
    if (value != text) {
      return AppTexts.passwordsDoNotMatchError;
    }
    return null;
  }

  static String? validateAccountName(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyAccountNameError;
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyAmountError;
    }
    final double? amount = double.tryParse(value);
    if (amount == null || amount < 0) {
      return AppTexts.positiveAmountError;
    }
    return null;
  }

  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyCardNumberError;
    }
    // Remover espacios y caracteres no numéricos
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return AppTexts.invalidCardNumberError;
    }
    return null;
  }

  static String? validateExpirationDate(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyExpirationDateError;
    }
    // Expected format: MM/YY or MM/YYYY
    final RegExp expDateRegExp = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$');
    if (!expDateRegExp.hasMatch(value)) {
      return AppTexts.invalidExpirationDateError;
    }

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    final currentYear = DateTime.now().year % 100; // Last two digits of the current year
    final currentMonth = DateTime.now().month;

    // If year is in 4 digits, convert to 2 digits
    final fullYear = year < 100 ? 2000 + year : year;
    final shortYear = fullYear % 100;

    // Check if the card is expired
    if (shortYear < currentYear || (shortYear == currentYear && month < currentMonth)) {
      return AppTexts.cardExpiredError;
    }

    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyCVVError;
    }
    if (value.length < 3 || value.length > 4) {
      return AppTexts.invalidCVVError;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return AppTexts.onlyNumberError;
    }
    return null;
  }

  static String? validateCardHolder(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyCardHolderError;
    }
    if (value.length < 2) {
      return AppTexts.shortCardHolderError;
    }
    return null;
  }

  static String? validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return AppTexts.emptyBirthdateError;
    }
    // Formato esperado: yyyy-MM-dd
    final RegExp birthdateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!birthdateRegExp.hasMatch(value)) {
      return AppTexts.invalidBirthdateError;
    }

    // final parts = value.split('-');
    // final day = int.parse(parts[2]);
    // final month = int.parse(parts[1]);
    // final year = int.parse(parts[0]);

    // final birthDate = DateTime(year, month, day);
    // final today = DateTime.now();
    // final age = today.year - birthDate.year - ((today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) ? 1 : 0);

    // if (age < 18) {
    //   return AppTexts.mustBeAdultError;
    // }

    return null;
  }
}

class EmailValidator {
  static final RegExp _emailRegExp = RegExp(r'^[a-zA-Z0-9_.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

  static bool validate(String email) {
    return _emailRegExp.hasMatch(email);
  }
}

class PhoneValidator {
  static final RegExp _phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');

  static bool validate(String phone) {
    return _phoneRegExp.hasMatch(phone);
  }
}

class NameValidator {
  static final RegExp _nameRegExp = RegExp(r'^[a-zA-Z]{3,}$');

  static bool validate(String name) {
    return _nameRegExp.hasMatch(name);
  }
}
