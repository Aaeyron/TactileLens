class MaterialModel {
  final int? id;
  final String title;
  final String subject;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String filePath;
  final DateTime uploadDate;

  MaterialModel({
    this.id,
    required this.title,
    required this.subject,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.filePath,
    required this.uploadDate,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      filePath: json['file_path'],
      uploadDate: DateTime.parse(json['upload_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_path': filePath,
      'upload_date': uploadDate.toIso8601String(),
    };
  }
}