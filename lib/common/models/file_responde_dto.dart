class FileResponseDto {
  final String id;
  final String url;
  final String? blurHash;

  const FileResponseDto({required this.id, required this.url, this.blurHash});

  factory FileResponseDto.fromJson(Map<String, dynamic> json) {
    return FileResponseDto(id: json['id'] as String, url: json['url'] as String, blurHash: json['blurHash'] as String?);
  }
}
