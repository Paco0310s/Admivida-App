class UpdateBusinessDto {
  final String? name;
  final String? description;
  final String? businessCategoryId;
  final String? fileId;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  UpdateBusinessDto({this.name, this.description, this.businessCategoryId, this.fileId, this.isActive, this.metadata});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (businessCategoryId != null) map['businessCategoryId'] = businessCategoryId;
    if (fileId != null) map['fileId'] = fileId;
    if (isActive != null) map['isActive'] = isActive;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }
}
