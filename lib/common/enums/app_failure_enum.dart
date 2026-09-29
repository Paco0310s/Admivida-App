/// Centralized enum handling all application, server, and network failures
/// across the Admivida ecosystem. Fully mapped to NestJS ErrorCodes.
enum AppFailure {
  // ===========================================================================
  // 🔑 USER & AUTH ERRORS
  // ===========================================================================
  firstnameRequired('El nombre es obligatorio.'),
  firstnameInvalid('El nombre debe ser texto válido.'),
  firstnameTooLong('El nombre no puede exceder los 255 caracteres.'),
  lastnameRequired('El apellido es obligatorio.'),
  lastnameInvalid('El apellido debe ser texto válido.'),
  lastnameTooLong('El apellido no puede exceder los 255 caracteres.'),
  phoneRequired('El número de teléfono es obligatorio.'),
  phoneInvalid('El formato del teléfono es inválido.'),
  emailRequired('El correo electrónico es obligatorio.'),
  emailOrPhoneRequired('Debes proporcionar un correo electrónico o teléfono.'),
  invalidEmail('El formato del correo electrónico es inválido.'),
  emailAlreadyExists('Este correo electrónico ya se encuentra registrado.'),
  phoneAlreadyExists('Este número de teléfono ya se encuentra registrado.'),
  passwordRequired('La contraseña es obligatoria.'),
  passwordInvalid('La contraseña debe ser texto válido.'),
  passwordTooShort('La contraseña debe tener al menos 8 caracteres.'),
  invalidCredentials('Correo electrónico o contraseña incorrectos.'),
  userNotFound('Usuario no encontrado.'),
  userInactive('La cuenta de usuario se encuentra inactiva.'),
  birthdateInvalid('La fecha de nacimiento no es válida.'),
  metadataInvalid('Los metadatos deben ser un objeto JSON válido.'),
  isActiveInvalid('El estado de activación debe ser un valor booleano.'),
  isVerifiedInvalid('El estado de verificación debe ser un valor booleano.'),
  isRegisteredInvalid('El estado de registro debe ser un valor booleano.'),
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
  businessNameTooLong(
    'El nombre del negocio no puede exceder los 255 caracteres.',
  ),
  businessDescriptionTooLong(
    'La descripción no puede exceder los 255 caracteres.',
  ),
  businessDescriptionInvalid(
    'La descripción del negocio debe ser texto válido.',
  ),
  businessNameInvalid('El nombre del negocio debe ser texto válido.'),
  businessCategoryIdRequired('La categoría del negocio es obligatoria.'),
  businessCategoryIdInvalid('El ID de la categoría debe ser un UUID válido.'),
  businessCategoryNotFound('No se encontró la categoría del negocio.'),
  businessCategoryNameRequired('El nombre de la categoría es obligatorio.'),
  businessCategoryNameInvalid(
    'El nombre de la categoría debe ser texto válido.',
  ),
  businessCategoryNameTooLong(
    'El nombre de la categoría no puede exceder los 255 caracteres.',
  ),
  businessCategoryDescriptionInvalid(
    'La descripción de la categoría debe ser texto válido.',
  ),
  businessCategoryDescriptionTooLong(
    'La descripción de la categoría no puede exceder los 255 caracteres.',
  ),
  businessNotFound('El negocio solicitado no existe.'),
  fileIdInvalid('El ID del archivo debe ser un UUID válido.'),

  // ===========================================================================
  // 👥 BUSINESS ROLES & MEMBERS ERRORS
  // ===========================================================================
  roleNameRequired('El nombre del rol es obligatorio.'),
  roleNameInvalid('El nombre del rol debe ser texto válido.'),
  roleNameTooLong('El nombre del rol no puede exceder los 255 caracteres.'),
  roleDescriptionInvalid(
    'La descripción del rol debe ser una cadena de texto.',
  ),
  roleDescriptionTooLong(
    'La descripción del rol no puede exceder los 255 caracteres.',
  ),
  roleNotFound('El rol especificado no existe.'),
  roleAlreadyExists('El nombre del rol ya se encuentra registrado.'),
  invalidRole('El valor del rol ingresado no es válido.'),
  roleIdRequired('El ID del rol es obligatorio.'),
  roleIdInvalid('El ID del rol debe ser un UUID válido.'),
  roleIdsRequired('Los IDs de los roles son obligatorios.'),
  roleIdsMustBeArray('Los IDs de los roles deben estructurarse en una lista.'),
  userCodeRequired('El código de usuario es obligatorio.'),
  userCodeInvalid(
    'El código de usuario debe cumplir con el formato 000-000-000.',
  ),
  memberAlreadyExists('Este usuario ya es miembro de este negocio.'),

  // ===========================================================================
  // 🧾 ACCOUNT TYPES, ACCOUNTS & APPLICATION SETTINGS
  // ===========================================================================
  accountTypeCodeRequired('El código del tipo de cuenta es obligatorio.'),
  accountTypeCodeInvalid(
    'El código debe usar solo letras mayúsculas y guiones bajos.',
  ),
  accountTypeCodeTooLong('El código no puede exceder los 50 caracteres.'),
  accountTypeNameRequired('El nombre del tipo de cuenta es obligatorio.'),
  accountTypeNameInvalid('El nombre del tipo de cuenta debe ser texto válido.'),
  accountTypeNameTooLong(
    'El nombre del tipo de cuenta no puede exceder los 255 caracteres.',
  ),
  accountTypeDescriptionInvalid(
    'La descripción del tipo de cuenta debe ser texto válido.',
  ),
  accountTypeDescriptionTooLong(
    'La descripción del tipo de cuenta no puede exceder los 255 caracteres.',
  ),
  accountNameRequired('El nombre de la cuenta es obligatorio.'),
  accountNameInvalid('El nombre de la cuenta debe ser texto válido.'),
  accountNameTooLong(
    'El nombre de la cuenta no puede exceder los 255 caracteres.',
  ),
  accountDescriptionTooLong(
    'La descripción de la cuenta no puede exceder los 255 caracteres.',
  ),
  accountDescriptionInvalid(
    'La descripción de la cuenta debe ser texto válido.',
  ),
  accountTypeIdRequired('El ID del tipo de cuenta es obligatorio.'),
  accountTypeIdInvalid('El ID del tipo de cuenta debe ser un UUID válido.'),
  accountBusinessIdInvalid(
    'El ID del negocio de la cuenta debe ser un UUID válido.',
  ),
  accountUserIdInvalid(
    'El ID del usuario de la cuenta debe ser un UUID válido.',
  ),
  appConstantKeyRequired('La clave de la constante es obligatoria.'),
  appConstantKeyInvalid('La clave de la constante debe ser texto válido.'),
  appConstantKeyTooLong(
    'La clave de la constante no puede exceder los 255 caracteres.',
  ),
  appConstantValueRequired('El valor de la constante es obligatorio.'),
  appConstantValueInvalid('El valor de la constante debe ser texto válido.'),
  appConstantValueTooLong(
    'El valor de la constante no puede exceder los 255 caracteres.',
  ),
  appConstantDescriptionTooLong(
    'La descripción de la constante no puede exceder los 255 caracteres.',
  ),
  appConstantDescriptionInvalid(
    'La descripción de la constante debe ser texto válido.',
  ),

  // ===========================================================================
  // 💳 PAYMENT METHODS
  // ===========================================================================
  paymentMethodCodeRequired('El código del método de pago es obligatorio.'),
  paymentMethodCodeInvalid('El código del método de pago no es válido.'),
  paymentMethodCodeTooLong(
    'El código del método de pago no puede exceder los 50 caracteres.',
  ),
  paymentMethodNameRequired('El nombre del método de pago es obligatorio.'),
  paymentMethodNameInvalid(
    'El nombre del método de pago debe ser texto válido.',
  ),
  paymentMethodNameTooLong(
    'El nombre del método de pago no puede exceder los 100 caracteres.',
  ),
  paymentMethodDescriptionTooLong(
    'La descripción del método de pago no puede exceder los 255 caracteres.',
  ),
  paymentMethodIsActiveInvalid(
    'El estado del método de pago debe ser booleano.',
  ),

  // ===========================================================================
  // 📦 PRODUCT CATALOG
  // ===========================================================================
  productCategoryNameRequired(
    'El nombre de la categoría de producto es obligatorio.',
  ),
  productCategoryNameInvalid(
    'El nombre de la categoría de producto debe ser texto válido.',
  ),
  productCategoryNameTooLong(
    'El nombre de la categoría no puede exceder los 150 caracteres.',
  ),
  productCategoryDescriptionInvalid(
    'La descripción de la categoría debe ser texto válido.',
  ),
  productCategoryParentIdInvalid(
    'El ID de la categoría padre debe ser un UUID válido.',
  ),
  productTypeCodeRequired('El código del tipo de producto es obligatorio.'),
  productTypeCodeInvalid(
    'El código del tipo de producto debe ser texto válido.',
  ),
  productTypeCodeTooLong(
    'El código del tipo de producto no puede exceder los 50 caracteres.',
  ),
  productTypeNameRequired('El nombre del tipo de producto es obligatorio.'),
  productTypeNameInvalid(
    'El nombre del tipo de producto debe ser texto válido.',
  ),
  productTypeNameTooLong(
    'El nombre del tipo de producto no puede exceder los 100 caracteres.',
  ),
  productTypeDescriptionInvalid(
    'La descripción del tipo de producto debe ser texto válido.',
  ),
  productTypeAllowFractionsInvalid(
    'La opción de fracciones debe ser booleana.',
  ),
  productBusinessIdRequired('El ID del negocio del producto es obligatorio.'),
  productBusinessIdInvalid(
    'El ID del negocio del producto debe ser un UUID válido.',
  ),
  productTypeIdRequired('El ID del tipo de producto es obligatorio.'),
  productTypeIdInvalid('El ID del tipo de producto debe ser un UUID válido.'),
  productCategoryIdInvalid(
    'El ID de la categoría del producto debe ser un UUID válido.',
  ),
  productNameRequired('El nombre del producto es obligatorio.'),
  productNameInvalid('El nombre del producto debe ser texto válido.'),
  productNameTooLong(
    'El nombre del producto no puede exceder los 255 caracteres.',
  ),
  productDescriptionInvalid(
    'La descripción del producto debe ser texto válido.',
  ),
  productUnitOfMeasureInvalid('La unidad de medida no es válida.'),
  productIsActiveInvalid('El estado del producto debe ser booleano.'),
  productVariantsRequired('Debes proporcionar al menos una variante.'),
  productVariantsInvalid(
    'Las variantes del producto no tienen un formato válido.',
  ),
  productImagesInvalid(
    'Las imágenes del producto no tienen un formato válido.',
  ),
  productPageInvalid('La página debe ser un entero positivo.'),
  productLimitInvalid('El límite debe ser un entero entre 1 y 100.'),
  productSearchInvalid('La búsqueda debe ser texto válido.'),
  productStockFilterInvalid(
    'El filtro de stock debe ser un número no negativo.',
  ),
  productVariantIdInvalid('El ID de la variante debe ser un UUID válido.'),
  productVariantSkuInvalid('El SKU de la variante debe ser texto válido.'),
  productVariantSkuTooLong(
    'El SKU de la variante no puede exceder los 100 caracteres.',
  ),
  productVariantBarcodeInvalid('El código de barras debe ser texto válido.'),
  productVariantBarcodeTooLong(
    'El código de barras no puede exceder los 100 caracteres.',
  ),
  productVariantNameInvalid('El nombre de la variante debe ser texto válido.'),
  productVariantNameTooLong(
    'El nombre de la variante no puede exceder los 100 caracteres.',
  ),
  productVariantPurchasePriceInvalid('El precio de compra no es válido.'),
  productVariantSalePriceRequired('El precio de venta es obligatorio.'),
  productVariantSalePriceInvalid('El precio de venta no es válido.'),
  productVariantWholesalePriceInvalid('El precio de mayoreo no es válido.'),
  productVariantWholesaleQuantityInvalid(
    'La cantidad de mayoreo no es válida.',
  ),
  productVariantStockQuantityInvalid('La cantidad de stock no es válida.'),
  productVariantMinimumStockInvalid('El stock mínimo no es válido.'),
  productVariantMaximumStockInvalid('El stock máximo no es válido.'),
  productVariantExpirationDateInvalid('La fecha de caducidad no es válida.'),
  productVariantAttributesInvalid(
    'Los atributos de la variante deben ser un objeto válido.',
  ),
  productVariantImagesInvalid(
    'Las imágenes de la variante no tienen un formato válido.',
  ),
  productImageFileIdInvalid(
    'El ID del archivo de imagen debe ser un UUID válido.',
  ),
  productImageMainInvalid(
    'El indicador de imagen principal debe ser booleano.',
  ),
  productVariantNotFound('No se encontró la variante del producto.'),
  productVariantNotInBusiness('La variante no pertenece a este negocio.'),
  productVariantStockInsufficient(
    'No hay suficiente stock para esta variante.',
  ),
  productVariantStockUpdateFailed(
    'No se pudo actualizar el stock de la variante.',
  ),
  productVariantStockReasonInvalid(
    'El motivo del movimiento de stock no es válido.',
  ),
  productVariantStockReferenceInvalid(
    'La referencia del movimiento debe ser texto válido.',
  ),
  productVariantStockNotesInvalid(
    'Las notas del movimiento deben ser texto válido.',
  ),
  productCreateFailed('No se pudo crear el producto.'),
  productUpdateFailed('No se pudo actualizar el producto.'),
  productMigrationFailed('Falló la migración de productos.'),
  productMigrationItemFailed('No se pudo migrar este producto.'),

  // ===========================================================================
  // 🧾 SALES & TRANSACTIONS
  // ===========================================================================
  saleBusinessIdRequired('El ID del negocio de la venta es obligatorio.'),
  saleBusinessIdInvalid(
    'El ID del negocio de la venta debe ser un UUID válido.',
  ),
  saleSellerUserIdRequired('El ID del vendedor es obligatorio.'),
  saleSellerUserIdInvalid('El ID del vendedor debe ser un UUID válido.'),
  saleAccountIdRequired('El ID de la cuenta de la venta es obligatorio.'),
  saleAccountIdInvalid('El ID de la cuenta debe ser un UUID válido.'),
  salePaymentMethodIdRequired('El método de pago es obligatorio.'),
  salePaymentMethodIdInvalid(
    'El ID del método de pago debe ser un UUID válido.',
  ),
  saleClientUserIdInvalid('El ID del cliente debe ser un UUID válido.'),
  saleClientNameInvalid('El nombre del cliente debe ser texto válido.'),
  saleClientNameTooLong(
    'El nombre del cliente no puede exceder los 255 caracteres.',
  ),
  saleDiscountAmountInvalid('El descuento no es válido.'),
  saleAmountPaidInvalid('El monto pagado no es válido.'),
  saleStatusInvalid('El estado de la venta no es válido.'),
  saleNotesInvalid('Las notas de la venta deben ser texto válido.'),
  saleLatitudeInvalid('La latitud no es válida.'),
  saleLongitudeInvalid('La longitud no es válida.'),
  saleDateInvalid('La fecha de la venta no es válida.'),
  saleDetailsRequired('Debes proporcionar al menos un detalle de venta.'),
  saleDetailsInvalid('Los detalles de la venta no tienen un formato válido.'),
  saleDetailProductVariantIdRequired(
    'El ID de la variante vendida es obligatorio.',
  ),
  saleDetailProductVariantIdInvalid(
    'El ID de la variante vendida debe ser un UUID válido.',
  ),
  saleDetailQuantityRequired('La cantidad vendida es obligatoria.'),
  saleDetailQuantityInvalid('La cantidad vendida debe ser mayor que cero.'),
  saleDetailProductNameInvalid(
    'El nombre del producto vendido debe ser texto válido.',
  ),
  saleDetailProductNameTooLong(
    'El nombre del producto vendido no puede exceder los 255 caracteres.',
  ),
  saleDetailPriceInvalid('El precio del detalle de venta no es válido.'),
  saleDetailPriceRequired('El precio del detalle de venta es obligatorio.'),
  saleDetailPriceTypeInvalid('El tipo de precio no es válido.'),
  saleDetailCommentaryInvalid('El comentario debe ser texto válido.'),
  saleDetailCommentaryTooLong(
    'El comentario no puede exceder los 255 caracteres.',
  ),
  saleDetailIsPaidInvalid('El estado de pago debe ser booleano.'),
  saleSellerNotInBusiness('El vendedor no pertenece a este negocio.'),
  saleAmountBelowTotal(
    'El monto pagado no puede ser menor al total de una venta completada.',
  ),
  saleClientRequiredForCredit(
    'Se requiere un cliente registrado para crédito o apartado.',
  ),
  saleClientNotFound('No se encontró el cliente de la venta.'),
  saleCreditNotAllowedForPublic(
    'No se permiten créditos ni apartados para Público General.',
  ),
  saleCreateFailed('No se pudo procesar la venta.'),
  saleNotFound('No se encontró la venta.'),
  salesMigrationFailed('Falló la migración de ventas.'),
  salesMigrationItemFailed('No se pudo migrar esta venta.'),
  transactionTypeRequired('El tipo de transacción es obligatorio.'),
  transactionTypeInvalid('El tipo debe ser ingreso o egreso.'),
  transactionAmountRequired('El monto de la transacción es obligatorio.'),
  transactionAmountInvalid('El monto de la transacción no es válido.'),
  transactionDescriptionRequired(
    'La descripción de la transacción es obligatoria.',
  ),
  transactionDescriptionInvalid('La descripción debe ser texto válido.'),
  transactionDescriptionTooLong(
    'La descripción no puede exceder los 255 caracteres.',
  ),
  transactionPaymentMethodIdRequired(
    'El método de pago de la transacción es obligatorio.',
  ),
  transactionPaymentMethodIdInvalid(
    'El ID del método de pago debe ser un UUID válido.',
  ),
  transactionAccountIdRequired('La cuenta de la transacción es obligatoria.'),
  transactionAccountIdInvalid('El ID de la cuenta debe ser un UUID válido.'),
  transactionBusinessIdInvalid('El ID del negocio debe ser un UUID válido.'),
  transactionSaleIdInvalid('El ID de la venta debe ser un UUID válido.'),
  transactionPageInvalid('La página debe ser un número positivo.'),
  transactionLimitInvalid('El límite debe ser un número positivo.'),
  transactionQueryAccountIdInvalid(
    'El filtro de cuenta debe ser un UUID válido.',
  ),
  transactionReloadFailed('La transacción se guardó pero no pudo recuperarse.'),
  transactionCreateFailed('No se pudo crear la transacción.'),

  // ===========================================================================
  // 💰 COMMISSIONS & EMPLOYEE PAYMENTS
  // ===========================================================================
  commissionSaleDetailIdRequired(
    'El ID del detalle de comisión es obligatorio.',
  ),
  commissionSaleDetailIdInvalid(
    'El ID del detalle de comisión debe ser un UUID válido.',
  ),
  commissionAmountRequired('El monto de comisión es obligatorio.'),
  commissionAmountInvalid('El monto de comisión no es válido.'),
  commissionSellerUserIdRequired('El vendedor de la comisión es obligatorio.'),
  commissionSellerUserIdInvalid('El ID del vendedor debe ser un UUID válido.'),
  commissionNotesInvalid('Las notas de comisión deben ser texto válido.'),
  commissionItemsRequired('Los elementos de la comisión son obligatorios.'),
  commissionItemsInvalid(
    'Los elementos de la comisión no tienen un formato válido.',
  ),
  commissionSourceAccountIdRequired(
    'La cuenta de origen de la comisión es obligatoria.',
  ),
  commissionSourceAccountIdInvalid(
    'La cuenta de origen debe ser un UUID válido.',
  ),
  commissionDestinationAccountIdRequired(
    'La cuenta destino de la comisión es obligatoria.',
  ),
  commissionDestinationAccountIdInvalid(
    'La cuenta destino debe ser un UUID válido.',
  ),
  commissionPaymentMethodIdRequired(
    'El método de pago de la comisión es obligatorio.',
  ),
  commissionPaymentMethodIdInvalid(
    'El método de pago debe ser un UUID válido.',
  ),
  commissionPaidAmountRequired('El monto pagado de comisión es obligatorio.'),
  commissionPaidAmountInvalid('El monto pagado de comisión no es válido.'),
  commissionItemsNotPayable(
    'Algún elemento ya fue pagado, no existe o pertenece a otro vendedor.',
  ),
  commissionPaymentCreateFailed('No se pudo procesar el pago de comisión.'),
  employeeUserIdRequired('El empleado es obligatorio.'),
  employeeUserIdInvalid('El ID del empleado debe ser un UUID válido.'),
  employeePaymentAmountRequired(
    'El monto del pago al empleado es obligatorio.',
  ),
  employeePaymentAmountInvalid('El monto del pago al empleado no es válido.'),
  employeePaymentAmountMustBePositive(
    'El monto del pago debe ser mayor que cero.',
  ),
  employeePaymentNotesInvalid('Las notas del pago deben ser texto válido.'),
  employeePaymentSourceAccountIdRequired(
    'La cuenta de origen del pago es obligatoria.',
  ),
  employeePaymentSourceAccountIdInvalid(
    'La cuenta de origen debe ser un UUID válido.',
  ),
  employeePaymentDestinationAccountIdRequired(
    'La cuenta destino del pago es obligatoria.',
  ),
  employeePaymentDestinationAccountIdInvalid(
    'La cuenta destino debe ser un UUID válido.',
  ),
  employeePaymentMethodIdRequired('El método de pago es obligatorio.'),
  employeePaymentMethodIdInvalid('El método de pago debe ser un UUID válido.'),
  employeePaymentCreateFailed('No se pudo procesar el pago al empleado.'),

  // ===========================================================================
  // 🔐 ACCESS, REQUEST & INVENTORY ERRORS
  // ===========================================================================
  businessIdRequired('El ID del negocio es obligatorio.'),
  businessAllQueryInvalid('El parámetro de consulta all debe ser booleano.'),
  sellerUserIdRequired('El ID del vendedor es obligatorio.'),
  userContextNotFound('No se encontró el contexto del usuario autenticado.'),
  userNotMemberOfBusiness('El usuario no pertenece a este negocio.'),
  userBusinessSaveFailed('La membresía se guardó pero no pudo recuperarse.'),
  userBusinessUpdateFailed(
    'La membresía se actualizó pero no pudo recuperarse.',
  ),
  userBusinessRoleIdsInvalid('Los IDs de roles deben ser una lista.'),
  userBusinessRoleIdInvalid('Cada ID de rol debe ser un UUID válido.'),
  userBusinessCommissionTypeInvalid('El tipo de comisión no es válido.'),
  userBusinessCommissionValueInvalid('El valor de comisión no es válido.'),
  loginIdentifierRequired('El correo o teléfono es obligatorio.'),
  loginIdentifierInvalid('El correo o teléfono debe ser texto válido.'),
  businessRoleDescriptionInvalid(
    'La descripción del rol de negocio debe ser texto válido.',
  ),
  businessRoleDescriptionTooLong(
    'La descripción del rol no puede exceder los 255 caracteres.',
  ),
  platformRoleDescriptionInvalid(
    'La descripción del rol de plataforma debe ser texto válido.',
  ),
  platformRoleDescriptionTooLong(
    'La descripción del rol no puede exceder los 255 caracteres.',
  ),
  productTypePhysicalNotFound(
    'El tipo de producto físico no está configurado.',
  ),
  businessIdInvalid('El ID del negocio debe ser un UUID válido.'),
  platformRoleIdRequired('El ID del rol de plataforma es obligatorio.'),
  pageInvalid('La página debe ser un entero positivo.'),
  limitInvalid('El límite debe ser un entero entre 1 y 100.'),
  emailTooLong('El correo electrónico no puede exceder los 255 caracteres.'),
  inventoryMovementBusinessIdRequired(
    'El ID del negocio del movimiento es obligatorio.',
  ),
  inventoryMovementBusinessIdInvalid(
    'El ID del negocio debe ser un UUID válido.',
  ),
  inventoryMovementVariantIdRequired('El ID de la variante es obligatorio.'),
  inventoryMovementVariantIdInvalid(
    'El ID de la variante debe ser un UUID válido.',
  ),
  inventoryMovementTypeRequired('El tipo de movimiento es obligatorio.'),
  inventoryMovementTypeInvalid(
    'El tipo de movimiento debe ser entrada o salida.',
  ),
  inventoryMovementReasonRequired('El motivo del movimiento es obligatorio.'),
  inventoryMovementReasonInvalid('El motivo del movimiento no es válido.'),
  inventoryMovementQuantityRequired(
    'La cantidad del movimiento es obligatoria.',
  ),
  inventoryMovementQuantityInvalid('La cantidad debe ser mayor que cero.'),
  inventoryMovementPreviousStockRequired('El stock anterior es obligatorio.'),
  inventoryMovementPreviousStockInvalid('El stock anterior no es válido.'),
  inventoryMovementNewStockRequired('El stock nuevo es obligatorio.'),
  inventoryMovementNewStockInvalid('El stock nuevo no es válido.'),
  inventoryMovementReferenceInvalid('La referencia debe ser texto válido.'),
  inventoryMovementReferenceTooLong(
    'La referencia no puede exceder los 100 caracteres.',
  ),
  inventoryMovementNotesInvalid('Las notas deben ser texto válido.'),
  businessRoleRequired('No tienes el rol requerido en este negocio.'),
  invalidUuid('El ID proporcionado debe ser un UUID válido.'),
  endpointNotFound('No se encontró el endpoint solicitado.'),
  recordNotFound('No se encontró el registro solicitado.'),
  recordUpdateNotFound('No se encontró o no pudo actualizarse el registro.'),
  recordNotDeleted('El registro no está eliminado y no puede restaurarse.'),
  recordHardDeleteNotFound(
    'No se encontró el registro para eliminarlo permanentemente.',
  ),
  businessAccessDenied('No tienes acceso a este negocio.'),
  businessAdminRequired('Se requieren permisos de administrador del negocio.'),
  productNotFound('No se encontró el producto en este negocio.'),
  productMigrationInvalidResponse(
    'El proveedor de migración de productos respondió con un formato inválido.',
  ),
  salesMigrationInvalidResponse(
    'El proveedor de migración de ventas respondió con un formato inválido.',
  ),

  // ===========================================================================
  // 🌐 SERVER FALLBACKS
  // ===========================================================================
  httpError('No se pudo completar la solicitud.'),
  inMaintenanceModeNotFound(
    'No se encontró la configuración del modo mantenimiento.',
  ),
  businessRoleClientNotFound('No se encontró el rol de cliente del negocio.'),
  accountTypeReceivableNotFound(
    'No está configurado el tipo de cuenta por cobrar.',
  ),

  // ===========================================================================
  // 📊 PLATFORM & SYSTEM ERRORS
  // ===========================================================================
  platformRoleNameRequired('El nombre del rol de plataforma es obligatorio.'),
  platformRoleNameInvalid(
    'El nombre del rol de plataforma debe ser texto válido.',
  ),
  platformRoleNameTooLong(
    'El nombre del rol de plataforma no puede exceder los 100 caracteres.',
  ),
  platformRoleNotFound('El rol de plataforma no existe.'),
  platformRoleAlreadyExists('El rol de plataforma ya se encuentra registrado.'),
  platformRoleIdInvalid('El ID del rol de plataforma debe ser un UUID válido.'),
  unauthorizedRole(
    'No tienes los permisos de rol requeridos para esta acción.',
  ),
  masterBusinessRoleAdminNotFound(
    'El rol maestro de Administrador no fue encontrado.',
  ),
  accountTypeNotFound('El tipo de cuenta financiera no existe.'),
  accountTypeCashNotFound('La cuenta tipo Caja General no fue encontrada.'),

  // ===========================================================================
  // ⚡ NATIVE NETWORK ERRORS (Dio Client Fallbacks)
  // ===========================================================================
  connectionTimeout('Tiempo de espera agotado. Verifica tu conexión.'),
  sendTimeout('Tiempo de espera de envío agotado. Inténtalo de nuevo.'),
  receiveTimeout('El servidor tardó demasiado en responder.'),
  connectionError(
    'No hay conexión a internet o el servidor está fuera de línea.',
  ),
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
  fileUploadFailed(
    'Falló la carga del archivo en el servidor de almacenamiento.',
  ),
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
        final enumName = _failureNameFromCode(code.toUpperCase());
        for (final failure in AppFailure.values) {
          if (failure.name == enumName) return failure;
        }
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
      default:
        return _failureCodeFromName(name);
    }
  }
}

String _failureNameFromCode(String code) {
  final parts = code.toLowerCase().split('_');
  if (parts.isEmpty) return code.toLowerCase();

  return parts.first +
      parts.skip(1).map((part) {
        if (part.isEmpty) return '';
        return '${part[0].toUpperCase()}${part.substring(1)}';
      }).join();
}

String _failureCodeFromName(String name) {
  return name
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)}')
      .toUpperCase();
}
