// copyWith에서 "생략"과 "null로 지우기"를 구분하는 값
const Object _unset = Object();

class Goal {
  final int? id;
  final String title;
  final String? description;
  final int parentId;
  final int position;
  final bool isCompleted;
  final int progress;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Goal({
    this.id,
    required this.title,
    this.description,
    required this.parentId,
    required this.position,
    this.isCompleted = false,
    this.progress = 0,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'parent_id': parentId,
      'position': position,
      'is_completed': isCompleted ? 1 : 0,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      parentId: map['parent_id'] as int,
      position: map['position'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
      progress: map['progress'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    Object? description = _unset,
    int? parentId,
    int? position,
    bool? isCompleted,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MandalartBoard {
  final int? id;
  final String centerGoal;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Goal> subGoals;

  MandalartBoard({
    this.id,
    required this.centerGoal,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.subGoals = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'center_goal': centerGoal,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MandalartBoard.fromMap(Map<String, dynamic> map, {List<Goal>? goals}) {
    return MandalartBoard(
      id: map['id'] as int?,
      centerGoal: map['center_goal'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      subGoals: goals ?? [],
    );
  }

  MandalartBoard copyWith({
    int? id,
    String? centerGoal,
    Object? description = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Goal>? subGoals,
  }) {
    return MandalartBoard(
      id: id ?? this.id,
      centerGoal: centerGoal ?? this.centerGoal,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subGoals: subGoals ?? this.subGoals,
    );
  }

  int get overallProgress {
    if (subGoals.isEmpty) return 0;
    final totalProgress = subGoals.fold<int>(0, (sum, goal) => sum + goal.progress);
    return totalProgress ~/ subGoals.length;
  }
}
