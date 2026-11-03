class ChecklistItem {
  final int? id;
  final int goalId;
  final String title;
  final bool isDone;
  final int position;
  final DateTime createdAt;

  ChecklistItem({
    this.id,
    required this.goalId,
    required this.title,
    this.isDone = false,
    required this.position,
    required this.createdAt,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
      position: map['position'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

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
  final List<ChecklistItem> checklistItems;

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
    this.checklistItems = const [],
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

  factory Goal.fromMap(
    Map<String, dynamic> map, {
    List<ChecklistItem> checklistItems = const [],
  }) {
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
      checklistItems: checklistItems,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    String? description,
    bool clearDescription = false,
    int? parentId,
    int? position,
    bool? isCompleted,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChecklistItem>? checklistItems,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checklistItems: checklistItems ?? this.checklistItems,
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
    String? description,
    bool clearDescription = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Goal>? subGoals,
  }) {
    return MandalartBoard(
      id: id ?? this.id,
      centerGoal: centerGoal ?? this.centerGoal,
      description: clearDescription ? null : description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subGoals: subGoals ?? this.subGoals,
    );
  }

  int get overallProgress {
    final filledGoals = subGoals.where((goal) => goal.title.isNotEmpty);
    if (filledGoals.isEmpty) return 0;
    final totalProgress = filledGoals.fold<int>(0, (sum, goal) => sum + goal.progress);
    return totalProgress ~/ filledGoals.length;
  }
}
