/// Centralized enum handling all application, server, and network failures
/// across the Admivida ecosystem. Fully mapped to NestJS ErrorCodes.
enum AppFailure {
  // ===========================================================================
  // 🔑 USER & AUTH ERRORS
  // ===========================================================================
  firstnameRequired('El nombre es obligatorio.'),
  firstnameTooLong('El nombre no puede exceder los 255 caracteres.'),
  lastnameRequired('El apellido es obligatorio.'),
  lastnameTooLong('El apellido no puede exceder los 255 caracteres.'),
  phoneRequired('El número de teléfono es obligatorio.'),
  phoneInvalid('El formato del teléfono es inválido.'),
  emailRequired('El correo electrónico es obligatorio.'),
  invalidEmail('El formato del correo electrónico es inválido.'),
  emailAlreadyExists('Este correo electrónico ya se encuentra registrado.'),
  phoneAlreadyExists('Este número de teléfono ya se encuentra registrado.'),
  passwordRequired('La contraseña es obligatoria.'),
  passwordTooShort('La contraseña debe tener al menos 8 caracteres.'),
  invalidCredentials('Correo electrónico o contraseña incorrectos.'),
  userNotFound('Usuario no encontrado.'),
  userInactive('La cuenta de usuario se encuentra inactiva.'),
  birthdateInvalid('La fecha de nacimiento no es válida.'),
  metadataInvalid('Los metadatos deben ser un objeto JSON válido.'),
  isActiveInvalid('El estado de activación debe ser un valor booleano.'),
  userIdRequired('El ID de usuario es obligatorio.'),
  userIdInvalid('El ID de usuario debe ser un UUID válido.'),

  // ===========================================================================
  // 🛡️ TOKEN ERRORS
  // ===========================================================================
  invalidToken('El token de autenticación es inválido.'),
  expiredToken('La sesión ha expirado. Por favor, inicia sesión de nuevo.'),
  missingToken('El token de autenticación no fue proporcionado.'),
  refreshTokenExpired('La sesión ha caducado por inactividad.'),
  refreshTokenRequired('El token de refresco es obligatorio.'),
  refreshTokenInvalid('El token de refresco es inválido.'),

  // ===========================================================================
  // 💼 BUSINESS ERRORS
  // ===========================================================================
  businessNameRequired('El nombre del negocio es obligatorio.'),
  businessNameTooLong('El nombre del negocio no puede exceder los 255 caracteres.'),
  businessDescriptionTooLong('La descripción no puede exceder los 255 caracteres.'),
  businessCategoryIdRequired('La categoría del negocio es obligatoria.'),
  businessCategoryIdInvalid('El ID de la categoría debe ser un UUID válido.'),
  businessCategoryNotFound('No se encontró la categoría del negocio.'),
  businessNotFound('El negocio solicitado no existe.'),
  fileIdInvalid('El ID del archivo debe ser un UUID válido.'),

  // ===========================================================================
  // 👥 BUSINESS ROLES & MEMBERS ERRORS
  // ===========================================================================
  roleNameRequired('El nombre del rol es obligatorio.'),
  roleNameTooLong('El nombre del rol no puede exceder los 255 caracteres.'),
  roleDescriptionInvalid('La descripción del rol debe ser una cadena de texto.'),
  roleDescriptionTooLong('La descripción del rol no puede exceder los 255 caracteres.'),
  roleNotFound('El rol especificado no existe.'),
  roleAlreadyExists('El nombre del rol ya se encuentra registrado.'),
  invalidRole('El valor del rol ingresado no es válido.'),
  roleIdRequired('El ID del rol es obligatorio.'),
  roleIdInvalid('El ID del rol debe ser un UUID válido.'),
  roleIdsRequired('Los IDs de los roles son obligatorios.'),
  roleIdsMustBeArray('Los IDs de los roles deben estructurarse en una lista.'),
  userCodeRequired('El código de usuario es obligatorio.'),
  userCodeInvalid('El código de usuario debe cumplir con el formato 000-000-000.'),
  memberAlreadyExists('Este usuario ya es miembro de este negocio.'),

  // ===========================================================================
  // 📊 PLATFORM & SYSTEM ERRORS
  // ===========================================================================
  platformRoleNameRequired('El nombre del rol de plataforma es obligatorio.'),
  platformRoleNameTooLong('El nombre del rol de plataforma no puede exceder los 100 caracteres.'),
  platformRoleNotFound('El rol de plataforma no existe.'),
  platformRoleAlreadyExists('El rol de plataforma ya se encuentra registrado.'),
  platformRoleIdInvalid('El ID del rol de plataforma debe ser un UUID válido.'),
  unauthorizedRole('No tienes los permisos de rol requeridos para esta acción.'),
  masterBusinessRoleAdminNotFound('El rol maestro de Administrador no fue encontrado.'),
  accountTypeNotFound('El tipo de cuenta financiera no existe.'),
  accountTypeCashNotFound('La cuenta tipo Caja General no fue encontrada.'),

  // ===========================================================================
  // ⚡ NATIVE NETWORK ERRORS (Dio Client Fallbacks)
  // ===========================================================================
  connectionTimeout('Tiempo de espera agotado. Verifica tu conexión.'),
  sendTimeout('Tiempo de espera de envío agotado. Inténtalo de nuevo.'),
  receiveTimeout('El servidor tardó demasiado en responder.'),
  connectionError('No hay conexión a internet o el servidor está fuera de línea.'),
  cancelled('La petición fue cancelada por la aplicación.'),

  // ===========================================================================
  // 🌐 GENERAL ERRORS
  // ===========================================================================
  validationFailed('La validación de los datos falló.'),
  invalidRequestBody('El cuerpo de la petición es inválido.'),
  resourceNotFound('El recurso solicitado no pudo ser encontrado.'),
  conflict('Ocurrió un conflicto con los datos en el servidor.'),
  internalServerError('Ocurrió un error interno en el servidor.'),
  unauthorized('Acceso denegado. Inicia sesión.'),
  forbidden('No tienes permisos suficientes para realizar esta acción.'),
  fileUploadFailed('Falló la carga del archivo en el servidor de almacenamiento.'),
  noFileUpload('No se proporcionó ningún archivo para subir.'),
  fileNotFound('El archivo solicitado no existe.'),
  appConstantNotFound('La constante de la aplicación no fue encontrada.'),
  unexpectedError('Ocurrió un error inesperado en la aplicación.'),
  unknownError('Ocurrió un error desconocido.');

  final String message;
  const AppFailure(this.message);

  /// Safely maps any String error tag from the backend or Dio to the unified [AppFailure] enum.
  factory AppFailure.fromCode(String? code) {
    if (code == null || code.isEmpty) return AppFailure.unknownError;

    switch (code.toUpperCase()) {
      // --- USER & AUTH ERRORS ---
      case 'FIRSTNAME_REQUIRED':
        return AppFailure.firstnameRequired;
      case 'FIRSTNAME_TOO_LONG':
        return AppFailure.firstnameTooLong;
      case 'LASTNAME_REQUIRED':
        return AppFailure.lastnameRequired;
      case 'LASTNAME_TOO_LONG':
        return AppFailure.lastnameTooLong;
      case 'PHONE_REQUIRED':
        return AppFailure.phoneRequired;
      case 'PHONE_INVALID':
        return AppFailure.phoneInvalid;
      case 'EMAIL_REQUIRED':
        return AppFailure.emailRequired;
      case 'INVALID_EMAIL':
        return AppFailure.invalidEmail;
      case 'EMAIL_ALREADY_EXISTS':
        return AppFailure.emailAlreadyExists;
      case 'PHONE_ALREADY_EXISTS':
        return AppFailure.phoneAlreadyExists;
      case 'PASSWORD_REQUIRED':
        return AppFailure.passwordRequired;
      case 'PASSWORD_TOO_SHORT':
        return AppFailure.passwordTooShort;
      case 'INVALID_CREDENTIALS':
        return AppFailure.invalidCredentials;
      case 'USER_NOT_FOUND':
        return AppFailure.userNotFound;
      case 'USER_INACTIVE':
        return AppFailure.userInactive;
      case 'BIRTHDATE_INVALID':
        return AppFailure.birthdateInvalid;
      case 'METADATA_INVALID':
        return AppFailure.metadataInvalid;
      case 'IS_ACTIVE_INVALID':
        return AppFailure.isActiveInvalid;
      case 'USER_ID_REQUIRED':
        return AppFailure.userIdRequired;
      case 'USER_ID_INVALID':
        return AppFailure.userIdInvalid;

      // --- TOKEN ERRORS ---
      case 'INVALID_TOKEN':
        return AppFailure.invalidToken;
      case 'EXPIRED_TOKEN':
        return AppFailure.expiredToken;
      case 'MISSING_TOKEN':
        return AppFailure.missingToken;
      case 'REFRESH_TOKEN_EXPIRED':
        return AppFailure.refreshTokenExpired;
      case 'REFRESH_TOKEN_REQUIRED':
        return AppFailure.refreshTokenRequired;
      case 'REFRESH_TOKEN_INVALID':
        return AppFailure.refreshTokenInvalid;

      // --- BUSINESS ERRORS ---
      case 'BUSINESS_NAME_REQUIRED':
        return AppFailure.businessNameRequired;
      case 'BUSINESS_NAME_TOO_LONG':
        return AppFailure.businessNameTooLong;
      case 'BUSINESS_DESCRIPTION_TOO_LONG':
        return AppFailure.businessDescriptionTooLong;
      case 'BUSINESS_CATEGORY_ID_REQUIRED':
        return AppFailure.businessCategoryIdRequired;
      case 'BUSINESS_CATEGORY_ID_INVALID':
        return AppFailure.businessCategoryIdInvalid;
      case 'BUSINESS_CATEGORY_NOT_FOUND':
        return AppFailure.businessCategoryNotFound;
      case 'BUSINESS_NOT_FOUND':
        return AppFailure.businessNotFound;
      case 'FILE_ID_INVALID':
        return AppFailure.fileIdInvalid;

      // --- BUSINESS ROLES & MEMBERS ERRORS ---
      case 'ROLE_NAME_REQUIRED':
        return AppFailure.roleNameRequired;
      case 'ROLE_NAME_TOO_LONG':
        return AppFailure.roleNameTooLong;
      case 'ROLE_DESCRIPTION_INVALID':
        return AppFailure.roleDescriptionInvalid;
      case 'ROLE_DESCRIPTION_TOO_LONG':
        return AppFailure.roleDescriptionTooLong;
      case 'ROLE_NOT_FOUND':
        return AppFailure.roleNotFound;
      case 'ROLE_ALREADY_EXISTS':
        return AppFailure.roleAlreadyExists;
      case 'INVALID_ROLE':
        return AppFailure.invalidRole;
      case 'ROLE_ID_REQUIRED':
        return AppFailure.roleIdRequired;
      case 'ROLE_ID_INVALID':
        return AppFailure.roleIdInvalid;
      case 'ROLE_IDS_REQUIRED':
        return AppFailure.roleIdsRequired;
      case 'ROLE_IDS_MUST_BE_ARRAY':
        return AppFailure.roleIdsMustBeArray;
      case 'USER_CODE_REQUIRED':
        return AppFailure.userCodeRequired;
      case 'USER_CODE_INVALID':
        return AppFailure.userCodeInvalid;
      case 'MEMBER_ALREADY_EXISTS':
        return AppFailure.memberAlreadyExists;

      // --- PLATFORM ROLE ERRORS ---
      case 'PLATFORM_ROLE_NAME_REQUIRED':
        return AppFailure.platformRoleNameRequired;
      case 'PLATFORM_ROLE_NAME_TOO_LONG':
        return AppFailure.platformRoleNameTooLong;
      case 'PLATFORM_ROLE_NOT_FOUND':
        return AppFailure.platformRoleNotFound;
      case 'PLATFORM_ROLE_ALREADY_EXISTS':
        return AppFailure.platformRoleAlreadyExists;
      case 'PLATFORM_ROLE_ID_INVALID':
        return AppFailure.platformRoleIdInvalid;
      case 'UNAUTHORIZED_ROLE':
        return AppFailure.unauthorizedRole;
      case 'MASTER_BUSINESS_ROLE_ADMIN_NOT_FOUND':
        return AppFailure.masterBusinessRoleAdminNotFound;
      case 'ACCOUNT_TYPE_NOT_FOUND':
        return AppFailure.accountTypeNotFound;
      case 'ACCOUNT_TYPE_CASH_NOT_FOUND':
        return AppFailure.accountTypeCashNotFound;

      // --- NATIVE NETWORK CODES ---
      case 'CONNECTION_TIMEOUT':
        return AppFailure.connectionTimeout;
      case 'SEND_TIMEOUT':
        return AppFailure.sendTimeout;
      case 'RECEIVE_TIMEOUT':
        return AppFailure.receiveTimeout;
      case 'CONNECTION_ERROR':
        return AppFailure.connectionError;
      case 'CANCELLED':
        return AppFailure.cancelled;

      // --- GENERAL ERRORS ---
      case 'VALIDATION_FAILED':
        return AppFailure.validationFailed;
      case 'INVALID_REQUEST_BODY':
        return AppFailure.invalidRequestBody;
      case 'RESOURCE_NOT_FOUND':
        return AppFailure.resourceNotFound;
      case 'CONFLICT':
        return AppFailure.conflict;
      case 'INTERNAL_SERVER_ERROR':
        return AppFailure.internalServerError;
      case 'UNAUTHORIZED':
        return AppFailure.unauthorized;
      case 'FORBIDDEN':
        return AppFailure.forbidden;
      case 'FILE_UPLOAD_FAILED':
        return AppFailure.fileUploadFailed;
      case 'NO_FILE_UPLOAD':
        return AppFailure.noFileUpload;
      case 'FILE_NOT_FOUND':
        return AppFailure.fileNotFound;
      case 'APP_CONSTANT_NOT_FOUND':
        return AppFailure.appConstantNotFound;

      default:
        return AppFailure.unknownError;
    }
  }

  /// Converts the current enum state into its exact match backend String string value representation.
  String toCode() {
    switch (this) {
      case AppFailure.firstnameRequired:
        return 'FIRSTNAME_REQUIRED';
      case AppFailure.firstnameTooLong:
        return 'FIRSTNAME_TOO_LONG';
      case AppFailure.lastnameRequired:
        return 'LASTNAME_REQUIRED';
      case AppFailure.lastnameTooLong:
        return 'LASTNAME_TOO_LONG';
      case AppFailure.phoneRequired:
        return 'PHONE_REQUIRED';
      case AppFailure.phoneInvalid:
        return 'PHONE_INVALID';
      case AppFailure.emailRequired:
        return 'EMAIL_REQUIRED';
      case AppFailure.invalidEmail:
        return 'INVALID_EMAIL';
      case AppFailure.emailAlreadyExists:
        return 'EMAIL_ALREADY_EXISTS';
      case AppFailure.phoneAlreadyExists:
        return 'PHONE_ALREADY_EXISTS';
      case AppFailure.passwordRequired:
        return 'PASSWORD_REQUIRED';
      case AppFailure.passwordTooShort:
        return 'PASSWORD_TOO_SHORT';
      case AppFailure.invalidCredentials:
        return 'INVALID_CREDENTIALS';
      case AppFailure.userNotFound:
        return 'USER_NOT_FOUND';
      case AppFailure.userInactive:
        return 'USER_INACTIVE';
      case AppFailure.birthdateInvalid:
        return 'BIRTHDATE_INVALID';
      case AppFailure.metadataInvalid:
        return 'METADATA_INVALID';
      case AppFailure.isActiveInvalid:
        return 'IS_ACTIVE_INVALID';
      case AppFailure.userIdRequired:
        return 'USER_ID_REQUIRED';
      case AppFailure.userIdInvalid:
        return 'USER_ID_INVALID';
      case AppFailure.invalidToken:
        return 'INVALID_TOKEN';
      case AppFailure.expiredToken:
        return 'EXPIRED_TOKEN';
      case AppFailure.missingToken:
        return 'MISSING_TOKEN';
      case AppFailure.refreshTokenExpired:
        return 'REFRESH_TOKEN_EXPIRED';
      case AppFailure.refreshTokenRequired:
        return 'REFRESH_TOKEN_REQUIRED';
      case AppFailure.refreshTokenInvalid:
        return 'REFRESH_TOKEN_INVALID';
      case AppFailure.businessNameRequired:
        return 'BUSINESS_NAME_REQUIRED';
      case AppFailure.businessNameTooLong:
        return 'BUSINESS_NAME_TOO_LONG';
      case AppFailure.businessDescriptionTooLong:
        return 'BUSINESS_DESCRIPTION_TOO_LONG';
      case AppFailure.businessCategoryIdRequired:
        return 'BUSINESS_CATEGORY_ID_REQUIRED';
      case AppFailure.businessCategoryIdInvalid:
        return 'BUSINESS_CATEGORY_ID_INVALID';
      case AppFailure.businessCategoryNotFound:
        return 'BUSINESS_CATEGORY_NOT_FOUND';
      case AppFailure.businessNotFound:
        return 'BUSINESS_NOT_FOUND';
      case AppFailure.fileIdInvalid:
        return 'FILE_ID_INVALID';
      case AppFailure.roleNameRequired:
        return 'ROLE_NAME_REQUIRED';
      case AppFailure.roleNameTooLong:
        return 'ROLE_NAME_TOO_LONG';
      case AppFailure.roleDescriptionInvalid:
        return 'ROLE_DESCRIPTION_INVALID';
      case AppFailure.roleDescriptionTooLong:
        return 'ROLE_DESCRIPTION_TOO_LONG';
      case AppFailure.roleNotFound:
        return 'ROLE_NOT_FOUND';
      case AppFailure.roleAlreadyExists:
        return 'ROLE_ALREADY_EXISTS';
      case AppFailure.invalidRole:
        return 'INVALID_ROLE';
      case AppFailure.roleIdRequired:
        return 'ROLE_ID_REQUIRED';
      case AppFailure.roleIdInvalid:
        return 'ROLE_ID_INVALID';
      case AppFailure.roleIdsRequired:
        return 'ROLE_IDS_REQUIRED';
      case AppFailure.roleIdsMustBeArray:
        return 'ROLE_IDS_MUST_BE_ARRAY';
      case AppFailure.userCodeRequired:
        return 'USER_CODE_REQUIRED';
      case AppFailure.userCodeInvalid:
        return 'USER_CODE_INVALID';
      case AppFailure.memberAlreadyExists:
        return 'MEMBER_ALREADY_EXISTS';
      case AppFailure.platformRoleNameRequired:
        return 'PLATFORM_ROLE_NAME_REQUIRED';
      case AppFailure.platformRoleNameTooLong:
        return 'PLATFORM_ROLE_NAME_TOO_LONG';
      case AppFailure.platformRoleNotFound:
        return 'PLATFORM_ROLE_NOT_FOUND';
      case AppFailure.platformRoleAlreadyExists:
        return 'PLATFORM_ROLE_ALREADY_EXISTS';
      case AppFailure.platformRoleIdInvalid:
        return 'PLATFORM_ROLE_ID_INVALID';
      case AppFailure.unauthorizedRole:
        return 'UNAUTHORIZED_ROLE';
      case AppFailure.masterBusinessRoleAdminNotFound:
        return 'MASTER_BUSINESS_ROLE_ADMIN_NOT_FOUND';
      case AppFailure.accountTypeNotFound:
        return 'ACCOUNT_TYPE_NOT_FOUND';
      case AppFailure.accountTypeCashNotFound:
        return 'ACCOUNT_TYPE_CASH_NOT_FOUND';
      case AppFailure.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case AppFailure.sendTimeout:
        return 'SEND_TIMEOUT';
      case AppFailure.receiveTimeout:
        return 'RECEIVE_TIMEOUT';
      case AppFailure.connectionError:
        return 'CONNECTION_ERROR';
      case AppFailure.cancelled:
        return 'CANCELLED';
      case AppFailure.validationFailed:
        return 'VALIDATION_FAILED';
      case AppFailure.invalidRequestBody:
        return 'INVALID_REQUEST_BODY';
      case AppFailure.resourceNotFound:
        return 'RESOURCE_NOT_FOUND';
      case AppFailure.conflict:
        return 'CONFLICT';
      case AppFailure.internalServerError:
        return 'INTERNAL_SERVER_ERROR';
      case AppFailure.unauthorized:
        return 'UNAUTHORIZED';
      case AppFailure.forbidden:
        return 'FORBIDDEN';
      case AppFailure.fileUploadFailed:
        return 'FILE_UPLOAD_FAILED';
      case AppFailure.noFileUpload:
        return 'NO_FILE_UPLOAD';
      case AppFailure.fileNotFound:
        return 'FILE_NOT_FOUND';
      case AppFailure.appConstantNotFound:
        return 'APP_CONSTANT_NOT_FOUND';
      case AppFailure.unexpectedError:
        return 'UNEXPECTED_ERROR';
      case AppFailure.unknownError:
        return 'UNKNOWN_ERROR';
    }
  }
}
