import 'package:admivida/business/features/add_product/add_product_provider.dart';
import 'package:admivida/business/features/add_product/models/add_product_model.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/business/features/products/products_service.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/picker_file.dart';
import 'package:admivida/common/services/file_service.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:admivida/common/widgets/barcode_scanner_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _pickedFile;
  String? _fileId;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;
  bool _isActive = true;
  String _unitOfMeasure = 'PZ';
  String? _selectedCategoryId;
  String? _selectedProductTypeId;

  final List<_VariantField> _variantFields = [_VariantField()];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final field in _variantFields) {
      field.dispose();
    }
    super.dispose();
  }

  /// Captura de foto principal del producto comprimida en RAM
  Future<void> _pickMainFile(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1200, maxHeight: 1200);

      if (picked == null) return;

      setState(() {
        _pickedFile = picked;
        _fileId = null;
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showError(context, 'La cámara no está disponible o no es compatible en esta plataforma.');
    }
  }

  /// Muestra modal de selección (Cámara o Galería) para una variante específica
  void _showImageSourceModal(_VariantField field) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText('Seleccionar Origen de la Foto', fontWeight: FontWeight.bold, fontSize: 16),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.kPrimaryColor),
                  title: const Text('Tomar Foto con Cámara'),
                  subtitle: const Text('Rápido para inventario en caja'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickVariantImage(field, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.kPrimaryColor),
                  title: const Text('Elegir de la Galería'),
                  subtitle: const Text('Seleccionar imagen editada o diseñada'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickVariantImage(field, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Captura de foto de variante con límites estrictos de resolución para evitar OOM
  Future<void> _pickVariantImage(_VariantField field, ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1200, maxHeight: 1200);

      if (picked == null) return;

      setState(() {
        field.pickedImages.add(picked);
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showError(context, 'La cámara no está disponible o no es compatible en esta plataforma.');
    }
  }

  void _addVariantRow() {
    setState(() {
      _variantFields.add(_VariantField());
    });
  }

  void _removeVariantRow(int index) {
    setState(() {
      _variantFields[index].dispose();
      _variantFields.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProductTypeId == null || _selectedProductTypeId!.isEmpty) {
      SnackbarUtil.showError(context, 'Por favor selecciona un tipo de producto');
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Subir la imagen general del producto si existe
    String? finalFileId = _fileId;
    if (_pickedFile != null && finalFileId == null) {
      setState(() => _isUploadingImage = true);

      final uploadResult = await FileService.uploadImage(_pickedFile!.path);

      if (!mounted) return;

      setState(() => _isUploadingImage = false);

      finalFileId = uploadResult.when(
        (failure) {
          SnackbarUtil.showError(context, '${AppTexts.errorUploadingImage}: ${failure.message}');
          return null;
        },
        (fileResponse) {
          _fileId = fileResponse.id;
          return fileResponse.id;
        },
      );

      if (finalFileId == null) {
        setState(() => _isSubmitting = false);
        return;
      }
    }

    // 2. Subida secuencial de fotos por variante
    final List<CreateProductVariantDto> variants = [];

    for (final field in _variantFields) {
      final variantImageDtos = <CreateProductImageDto>[];

      for (int i = 0; i < field.pickedImages.length; i++) {
        final imageFile = field.pickedImages[i];
        final uploadRes = await FileService.uploadImage(imageFile.path);

        uploadRes.when(
          (failure) {
            SnackbarUtil.showError(context, 'Error al subir foto de variante: ${failure.message}');
          },
          (fileResponse) {
            variantImageDtos.add(CreateProductImageDto(fileId: fileResponse.id, main: i == 0));
          },
        );
      }

      // Atributos dinámicos key-value
      final attributes = <String, dynamic>{};
      for (final attributeField in field.attributeFields) {
        final key = attributeField.keyController.text.trim();
        final value = attributeField.valueController.text.trim();

        if (key.isNotEmpty) {
          attributes[key] = value;
        }
      }

      variants.add(
        CreateProductVariantDto(
          sku: field.skuController.text.trim().isEmpty ? null : field.skuController.text.trim(),
          barcode: field.barcodeController.text.trim().isEmpty ? null : field.barcodeController.text.trim(),
          name: field.variantNameController.text.trim().isEmpty ? null : field.variantNameController.text.trim(),
          purchasePrice: double.tryParse(field.purchasePriceController.text.trim()),
          salePrice: double.tryParse(field.salePriceController.text.trim()) ?? 0.0,
          wholesalePrice: double.tryParse(field.wholesalePriceController.text.trim()),
          wholesaleQuantity: double.tryParse(field.wholesaleQuantityController.text.trim()),
          stockQuantity: double.tryParse(field.stockQuantityController.text.trim()),
          minimumStock: double.tryParse(field.minimumStockController.text.trim()) ?? 0.0,
          maximumStock: double.tryParse(field.maximumStockController.text.trim()),
          attributes: attributes.isEmpty ? null : attributes,
          images: variantImageDtos,
        ),
      );
    }

    // 3. Ensamblar DTO completo
    final dto = CreateProductDto(
      businessId: widget.businessId,
      productTypeId: _selectedProductTypeId!,
      productCategoryId: _selectedCategoryId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      unitOfMeasure: _unitOfMeasure,
      isActive: _isActive,
      variants: variants,
      images: finalFileId == null ? const [] : [CreateProductImageDto(fileId: finalFileId, main: true)],
    );

    // 4. Enviar a NestJS
    final result = await ProductsService.createProduct(dto);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.when(
      (failure) {
        SnackbarUtil.showError(context, failure.message);
      },
      (product) {
        SnackbarUtil.showSuccess(context, '${AppTexts.productCreated}: ${product.name}');
        ref.invalidate(productsListProvider(widget.businessId));
        NavigationService.pop(context);
      },
    );
  }

  Widget _buildVariantEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(AppTexts.productVariantsLabel, fontWeight: FontWeight.bold),
            TextButton.icon(onPressed: _addVariantRow, icon: const Icon(Icons.add), label: Text(AppTexts.addVariantButton)),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_variantFields.length, (index) {
          final field = _variantFields[index];
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SKU y Barcode
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(text: AppTexts.productSkuLabel, hintText: AppTexts.productSkuHint, controller: field.skuController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        text: 'Código de Barras',
                        hintText: '7501234567890',
                        controller: field.barcodeController,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          tooltip: 'Escanear código de barras',
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (_) => BarcodeScannerSheet(
                                onCode: (scannedCode) {
                                  setState(() {
                                    field.barcodeController.text = scannedCode;
                                  });
                                  SnackbarUtil.showSuccess(context, 'Código asignado: $scannedCode');
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  text: AppTexts.productVariantNameLabel,
                  hintText: _variantFields.length == 1 ? 'General / Por Defecto' : AppTexts.productVariantNameHint,
                  controller: field.variantNameController,
                ),
                const SizedBox(height: 12),
                // Precios de Compra y Venta
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        text: AppTexts.productPurchasePriceLabel,
                        hintText: '\$60.00',
                        controller: field.purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        text: AppTexts.productSalePriceLabel,
                        hintText: '\$100.00',
                        controller: field.salePriceController,
                        isRequired: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Mayoreo
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        text: 'Precio Mayoreo',
                        hintText: '\$85.00',
                        controller: field.wholesalePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        text: 'Cant. Min. Mayoreo',
                        hintText: '10',
                        controller: field.wholesaleQuantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stocks
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        text: AppTexts.productStockLabel,
                        hintText: '30',
                        controller: field.stockQuantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        text: AppTexts.productMinimumStockLabel,
                        hintText: '5',
                        controller: field.minimumStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  text: AppTexts.productMaximumStockLabel,
                  hintText: '50',
                  controller: field.maximumStockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                _buildVariantImagePicker(field),
                const SizedBox(height: 12),
                _buildAttributeEditor(field),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _variantFields.length == 1 ? null : () => _removeVariantRow(index),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.kNeutral500,
                    tooltip: AppTexts.removeMetadata,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVariantImagePicker(_VariantField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText('Fotos de esta Variante', fontWeight: FontWeight.bold, fontSize: 13),
            TextButton.icon(
              onPressed: () => _showImageSourceModal(field),
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Agregar Foto', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (field.pickedImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: field.pickedImages.length,
              itemBuilder: (context, imgIndex) {
                final img = field.pickedImages[imgIndex];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.kNeutral300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PickerFile(xFile: img).getWidget(fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            field.pickedImages.removeAt(imgIndex);
                          });
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttributeEditor(_VariantField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(AppTexts.productAttributesLabel, fontWeight: FontWeight.bold),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  field.attributeFields.add(_AttributeField());
                });
              },
              icon: const Icon(Icons.add),
              label: Text(AppTexts.addProductAttributes),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(field.attributeFields.length, (attributeIndex) {
          final attributeField = field.attributeFields[attributeIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(text: AppTexts.metadataKey, hintText: AppTexts.productMetadataKeyHint, controller: attributeField.keyController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(text: AppTexts.metadataValue, hintText: AppTexts.productMetadataValueHint, controller: attributeField.valueController),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: field.attributeFields.length == 1
                      ? null
                      : () {
                          setState(() {
                            field.attributeFields[attributeIndex].dispose();
                            field.attributeFields.removeAt(attributeIndex);
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.kNeutral500,
                  tooltip: AppTexts.removeMetadata,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(AppTexts.fileImageLabel, fontWeight: FontWeight.bold),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(onPressed: () => _pickMainFile(ImageSource.gallery), icon: const Icon(Icons.attach_file), label: Text(AppTexts.chooseFile)),
            ElevatedButton.icon(onPressed: () => _pickMainFile(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(AppTexts.openCamera)),
          ],
        ),
        if (_pickedFile != null) ...[
          const SizedBox(height: 15),
          Text('${AppTexts.selectedFile} ${_pickedFile!.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: PickerFile(xFile: _pickedFile!).getWidget(fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isUploadingImage || _isSubmitting;

    return AppScaffold(
      title: AppTexts.addProductButton,
      appBar: AppBar(
        title: AppText(AppTexts.addProductButton, color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(isBusy),
      tablet: _buildContent(isBusy),
      desktop: _buildContent(isBusy),
      marginDesktop: 160,
    );
  }

  Widget _buildHeaderCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(AppTexts.productAddIntro, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText('Agrega los datos correspondientes para crear un nuevo producto.', color: AppColors.kNeutral600),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isBusy) {
    final productTypesAsync = ref.watch(productTypesProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider(widget.businessId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    text: AppTexts.productNameLabel,
                    hintText: AppTexts.productNameHint,
                    controller: _nameController,
                    isRequired: true,
                    validator: (value) => (value == null || value.trim().isEmpty) ? AppTexts.nameRequired : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    text: AppTexts.productDescriptionLabel,
                    hintText: AppTexts.productDescriptionHint,
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  productTypesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error al cargar tipos: $err'),
                    data: (types) {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de Producto *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        initialValue: _selectedProductTypeId,
                        items: types.map((type) {
                          return DropdownMenuItem<String>(value: type.id, child: Text(type.name));
                        }).toList(),
                        validator: (val) => val == null ? 'Selecciona un tipo de producto' : null,
                        onChanged: (selectedTypeId) {
                          setState(() {
                            _selectedProductTypeId = selectedTypeId;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error al cargar categorías: $err'),
                    data: (categories) {
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Categoría de Producto',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        initialValue: _selectedCategoryId,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(value: cat.id, child: Text(cat.name));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _unitOfMeasure,
                    decoration: InputDecoration(
                      labelText: AppTexts.productUnitOfMeasureLabel,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PZ', child: Text('PZ')),
                      DropdownMenuItem(value: 'KG', child: Text('KG')),
                      DropdownMenuItem(value: 'LT', child: Text('LT')),
                      DropdownMenuItem(value: 'ML', child: Text('ML')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _unitOfMeasure = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: AppText(AppTexts.productActiveLabel, color: AppColors.kNeutral900),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 16),
                  _buildFilePicker(),
                  const SizedBox(height: 16),
                  _buildVariantEditor(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isBusy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppTexts.saveProduct),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantField {
  final TextEditingController skuController;
  final TextEditingController barcodeController;
  final TextEditingController variantNameController;
  final TextEditingController purchasePriceController;
  final TextEditingController salePriceController;
  final TextEditingController wholesalePriceController;
  final TextEditingController wholesaleQuantityController;
  final TextEditingController stockQuantityController;
  final TextEditingController minimumStockController;
  final TextEditingController maximumStockController;
  final List<_AttributeField> attributeFields;
  final List<XFile> pickedImages;

  _VariantField({
    String sku = '',
    String barcode = '',
    String variantName = '',
    String purchasePrice = '',
    String salePrice = '',
    String wholesalePrice = '',
    String wholesaleQuantity = '',
    String stockQuantity = '',
    String minimumStock = '',
    String maximumStock = '',
  }) : skuController = TextEditingController(text: sku),
       barcodeController = TextEditingController(text: barcode),
       variantNameController = TextEditingController(text: variantName),
       purchasePriceController = TextEditingController(text: purchasePrice),
       salePriceController = TextEditingController(text: salePrice),
       wholesalePriceController = TextEditingController(text: wholesalePrice),
       wholesaleQuantityController = TextEditingController(text: wholesaleQuantity),
       stockQuantityController = TextEditingController(text: stockQuantity),
       minimumStockController = TextEditingController(text: minimumStock),
       maximumStockController = TextEditingController(text: maximumStock),
       attributeFields = [_AttributeField()],
       pickedImages = [];

  void dispose() {
    skuController.dispose();
    barcodeController.dispose();
    variantNameController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    wholesalePriceController.dispose();
    wholesaleQuantityController.dispose();
    stockQuantityController.dispose();
    minimumStockController.dispose();
    maximumStockController.dispose();
    for (final attributesField in attributeFields) {
      attributesField.dispose();
    }
  }
}

class _AttributeField {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _AttributeField({String key = '', String value = ''})
    : keyController = TextEditingController(text: key),
      valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
