class BlogResponse {
  final bool success;
  final List<BlogModel> data;
  final int? count;

  BlogResponse({required this.success, required this.data, this.count});

  factory BlogResponse.fromJson(Map<String, dynamic> json) {
    List<BlogModel> dataList = [];
    final dynamic data = json['data'] ?? json['result'];
    
    if (data != null) {
      if (data is List) {
        dataList = data
            .map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map) {
        dataList = [BlogModel.fromJson(data as Map<String, dynamic>)];
      }
    }
    return BlogResponse(
      success: json['success'] ?? (data != null),
      data: dataList,
      count: json['count'] as int? ?? dataList.length,
    );
  }
}

class BlogModel {
  final String id;
  final String baiguullagiinId;
  final String? barilgiinId;
  final String title;
  final String content;
  final List<String> images;
  final List<ReactionModel> reactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogModel({
    required this.id,
    required this.baiguullagiinId,
    this.barilgiinId,
    required this.title,
    required this.content,
    required this.images,
    required this.reactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    // Handle images which can be a list of strings or a list of objects with a 'path' field
    List<String> imagePaths = [];
    if (json['images'] != null && json['images'] is List) {
      for (var item in json['images']) {
        if (item is String) {
          imagePaths.add(item);
        } else if (item is Map && item.containsKey('path')) {
          imagePaths.add(item['path'].toString());
        }
      }
    }

    return BlogModel(
      id: json['_id']?.toString() ?? '',
      baiguullagiinId: json['baiguullagiinId']?.toString() ?? '',
      barilgiinId: json['barilgiinId']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      images: imagePaths,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((e) => ReactionModel.fromJson(e))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['ognoo'] != null ? DateTime.parse(json['ognoo']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  BlogModel copyWith({List<ReactionModel>? reactions}) {
    return BlogModel(
      id: id,
      baiguullagiinId: baiguullagiinId,
      barilgiinId: barilgiinId,
      title: title,
      content: content,
      images: images,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ReactionModel {
  final String emoji;
  final int count;
  final List<String> users;

  ReactionModel({
    required this.emoji,
    required this.count,
    required this.users,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      emoji: json['emoji']?.toString() ?? '',
      count: json['count'] as int? ?? 0,
      users: json['users'] != null ? List<String>.from(json['users']) : [],
    );
  }
}
