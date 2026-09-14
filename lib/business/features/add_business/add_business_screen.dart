import 'package:admivida/business/features/add_business/add_business_provider.dart';
import 'package:admivida/business/features/add_business/models/create_business_dto.dart';
import 'package:admivida/business/features/add_business/models/update_business_dto.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/models/files/picker_file.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/services/file_service.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class CreateOrUpdateBusinessScreen extends ConsumerStatefulWidget {
  /// Si [business] es nulo, la pantalla funciona en modo "Crear".
  /// Si se proporciona un negocio, funciona en modo "Editar".
  final BusinessModel? business;

  const CreateOrUpdateBusinessScreen({super.key, this.business});

  @override
  ConsumerState<CreateOrUpdateBusinessScreen> createState() => _CreateOrUpdateBusinessScreenState();
}

class _CreateOrUpdateBusinessScreenState extends ConsumerState<CreateOrUpdateBusinessScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _pickedFile;
  String? _fileId;
  bool _isUploadingImage = false;
  String? _selectedCategoryId;
  bool _isActive = true;

  final List<_MetadataField> _metadataFields = [];

  bool get isEditing => widget.business != null;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Llena los campos si estamos en modo edición
  void _loadExistingData() {
    if (!isEditing) {
      _metadataFields.add(_MetadataField());
      return;
    }

    final b = widget.business!;
    _nameController.text = b.name;
    _descriptionController.text = b.description ?? '';
    _isActive = b.isActive;
    _selectedCategoryId = b.businessCategoryId;
    _fileId = b.image?.id;

    if (b.metadata != null && b.metadata!.isNotEmpty) {
      b.metadata!.forEach((key, value) {
        _metadataFields.add(_MetadataField(key: key, value: value.toString()));
      });
    }

    // Si no traía metadata, dejamos un campo vacío listo para usar
    if (_metadataFields.isEmpty) {
      _metadataFields.add(_MetadataField());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final metadataField in _metadataFields) {
      metadataField.dispose();
    }
    super.dispose();
  }

  /// Handles image selection from camera or gallery source.
  Future<void> _pickFile(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);

      if (picked == null) return;

      setState(() {
        _pickedFile = picked;
        _fileId = null; // Reset fileId when a new image is selected
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showError(context, 'La cámara no está disponible o no es compatible en esta plataforma.');
    }
  }

  /// Transforms dynamic form key-value pairs into a clean Map structure.
  Map<String, dynamic> _buildMetadata() {
    final Map<String, dynamic> metadata = {};
    for (final metadataField in _metadataFields) {
      final key = metadataField.keyController.text.trim();
      final value = metadataField.valueController.text.trim();
      if (key.isNotEmpty) {
        metadata[key] = value;
      }
    }
    return metadata;
  }

  void _addMetadataRow() {
    setState(() {
      _metadataFields.add(_MetadataField());
    });
  }

  void _removeMetadataRow(int index) {
    setState(() {
      _metadataFields[index].dispose();
      _metadataFields.removeAt(index);
    });
  }

  /// Main submission pipeline: Uploads image if pending, builds DTO, and triggers provider.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      SnackbarUtil.showWarning(context, AppTexts.selectCategoryPrompt);
      return;
    }

    String? finalFileId = _fileId;

    // 1. Automatically upload selected image if a new one was picked
    if (_pickedFile != null) {
      setState(() => _isUploadingImage = true);

      final uploadResult = await FileService.uploadImage(_pickedFile!.path);

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

      // Abort submission if image upload failed
      if (finalFileId == null) return;
    }

    // 2. Dispatch the correct request based on mode
    if (isEditing) {
      final updateDto = UpdateBusinessDto(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        businessCategoryId: _selectedCategoryId,
        fileId: finalFileId,
        isActive: _isActive,
        metadata: _buildMetadata(),
      );

      ref.read(createOrUpdateBusinessProvider.notifier).submit(updateDto: updateDto, businessId: widget.business!.id);
    } else {
      final createDto = CreateBusinessDto(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        businessCategoryId: _selectedCategoryId!,
        fileId: finalFileId,
        isActive: _isActive,
        metadata: _buildMetadata(),
      );

      ref.read(createOrUpdateBusinessProvider.notifier).submit(createDto: createDto);
    }
  }

  Widget _buildMetadataEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(AppTexts.metadataLabel, fontWeight: FontWeight.bold),
            TextButton.icon(onPressed: _addMetadataRow, icon: const Icon(Icons.add), label: Text(AppTexts.addMetadata)),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_metadataFields.length, (index) {
          final field = _metadataFields[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(text: AppTexts.metadataKey, hintText: AppTexts.metadataKeyHint, controller: field.keyController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(text: AppTexts.metadataValue, hintText: AppTexts.metadataValueHint, controller: field.valueController),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _metadataFields.length == 1 ? null : () => _removeMetadataRow(index),
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
    // Variable para saber si tenemos una URL de imagen guardada en red
    final hasExistingNetworkImage = isEditing && widget.business?.image?.url != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(AppTexts.fileImageLabel, fontWeight: FontWeight.bold),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(onPressed: () => _pickFile(ImageSource.gallery), icon: const Icon(Icons.attach_file), label: Text(AppTexts.chooseFile)),
            ElevatedButton.icon(onPressed: () => _pickFile(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: Text(AppTexts.openCamera)),
          ],
        ),
        const SizedBox(height: 15),

        // Muestra la imagen nueva que el usuario acaba de seleccionar
        if (_pickedFile != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: PickerFile(xFile: _pickedFile!).getWidget(fit: BoxFit.cover),
              ),
            ),
          )
        // O muestra la imagen que ya estaba guardada en el negocio
        else if (hasExistingNetworkImage)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: AdaptedFile.network(widget.business!.image!.url).getWidget(fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Listen for business creation/update asynchronous state changes
    final formState = ref.watch(createOrUpdateBusinessProvider);
    final isSubmitting = formState.isLoading || _isUploadingImage;

    // Títulos dinámicos según el modo
    final screenTitle = isEditing ? 'Editar Negocio' : AppTexts.addBusinessButton;

    ref.listen(createOrUpdateBusinessProvider, (previous, next) {
      next.whenOrNull(
        data: (businessResult) {
          if (businessResult != null) {
            final actionText = isEditing ? 'actualizado' : AppTexts.registeredSuccessfully;
            SnackbarUtil.showSuccess(context, '${businessResult.name} $actionText');
            NavigationService.pop(context, result: businessResult);
          }
        },
        error: (error, stackTrace) {
          final message = error is HttpFailure ? error.message : AppTexts.errorServerResponse;
          SnackbarUtil.showError(context, message);
        },
      );
    });

    return AppScaffold(
      title: screenTitle,
      appBar: AppBar(
        title: AppText(screenTitle, color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(isSubmitting),
      tablet: _buildContent(isSubmitting),
      desktop: _buildContent(isSubmitting),
    );
  }

  Widget _buildHeaderCard() {
    final titleText = isEditing ? 'Actualizar Información' : AppTexts.saleAddIntro;
    final subtitleText = isEditing ? 'Modifica los datos de tu empresa.' : 'Agrega los datos correspondientes para crear una nueva empresa.';

    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(titleText, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText(subtitleText, color: AppColors.kNeutral600),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isSubmitting) {
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
                    text: AppTexts.businessNameLabel,
                    hintText: AppTexts.businessNameHint,
                    controller: _nameController,
                    isRequired: true,
                    validator: (value) => (value == null || value.trim().isEmpty) ? AppTexts.nameRequired : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    text: AppTexts.businessDescriptionLabel,
                    hintText: AppTexts.businessDescriptionHint,
                    controller: _descriptionController,
                    maxLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? AppTexts.descriptionRequired : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: AppText(AppTexts.businessActiveLabel, color: AppColors.kNeutral900),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 16),
                  BusinessCategoryDropdown(selectedCategoryId: _selectedCategoryId, onChanged: (value) => setState(() => _selectedCategoryId = value)),
                  const SizedBox(height: 16),
                  _buildFilePicker(),
                  const SizedBox(height: 16),
                  _buildMetadataEditor(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEditing ? 'Actualizar Negocio' : AppTexts.saveBusiness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataField {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _MetadataField({String key = '', String value = ''}) : keyController = TextEditingController(text: key), valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class BusinessCategoryDropdown extends ConsumerWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const BusinessCategoryDropdown({super.key, required this.selectedCategoryId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(businessCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => Text('${AppTexts.errorLoadingCategories} $error', style: const TextStyle(color: Colors.red)),
      data: (categories) {
        return DropdownButtonFormField<String>(
          initialValue: selectedCategoryId,
          decoration: InputDecoration(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [AppText(AppTexts.businessCategoryLabel, color: AppColors.kPrimary500)],
            ),
            border: const OutlineInputBorder(),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(value: category.id, child: Text(category.name));
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
