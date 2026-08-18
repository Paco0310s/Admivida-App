/// Data Transfer Object (DTO) for creating or updating a Business in Admivida.
class CreateBusinessDto {
  final String name;
  final String description;
  final String businessCategoryId;
  final String? fileId;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const CreateBusinessDto({
    required this.name,
    required this.description,
    required this.businessCategoryId,
    this.fileId,
    this.metadata = const {},
    this.isActive = true,
  });

  /// Converts the DTO instance into a clean JSON Map to send in the HTTP Body.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'businessCategoryId': businessCategoryId,
      if (fileId != null) 'fileId': fileId,
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  /// Optional copyWith for easy state mutation in Flutter forms/Riverpod
  CreateBusinessDto copyWith({String? name, String? description, String? businessCategoryId, String? fileId, Map<String, dynamic>? metadata}) {
    return CreateBusinessDto(
      name: name ?? this.name,
      description: description ?? this.description,
      businessCategoryId: businessCategoryId ?? this.businessCategoryId,
      fileId: fileId ?? this.fileId,
      metadata: metadata ?? this.metadata,
      isActive: isActive,
    );
  }
}
