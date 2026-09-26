class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final DateTime? createdAt;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? 'pdf',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'fileUrl': fileUrl,
        'fileType': fileType,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
