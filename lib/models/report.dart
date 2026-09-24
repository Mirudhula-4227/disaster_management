class Report {
  final String id;
  final String description;
  final String category;
  final int peopleAffected;
  final int vulnerablePeople;
  final String situation;
  final String assistance;
  final String userSelectedSeverity;
  final int createdAt;
  final String status;
  final double? priorityScore;
  final String? finalSeverity;

  Report({
    required this.id,
    required this.description,
    required this.category,
    required this.peopleAffected,
    required this.vulnerablePeople,
    required this.situation,
    required this.assistance,
    required this.userSelectedSeverity,
    required this.createdAt,
    required this.status,
    this.priorityScore,
    this.finalSeverity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'people_affected': peopleAffected,
      'vulnerable_people': vulnerablePeople,
      'situation': situation,
      'assistance': assistance,
      'user_selected_severity': userSelectedSeverity,
      'created_at': createdAt,
      'status': status,
      'priority_score': priorityScore,
      'final_severity': finalSeverity,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      peopleAffected: map['people_affected'] as int,
      vulnerablePeople: map['vulnerable_people'] as int,
      situation: map['situation'] as String,
      assistance: map['assistance'] as String,
      userSelectedSeverity: map['user_selected_severity'] as String,
      createdAt: map['created_at'] as int,
      status: map['status'] as String,
      priorityScore: map['priority_score'] as double?,
      finalSeverity: map['final_severity'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'description': description,
      'category': category,
      'people_affected': peopleAffected,
      'vulnerable_people': vulnerablePeople,
      'situation': situation,
      'assistance': assistance,
      'user_selected_severity': userSelectedSeverity,
    };
  }

  Report copyWith({
    String? status,
    double? priorityScore,
    String? finalSeverity,
  }) {
    return Report(
      id: id,
      description: description,
      category: category,
      peopleAffected: peopleAffected,
      vulnerablePeople: vulnerablePeople,
      situation: situation,
      assistance: assistance,
      userSelectedSeverity: userSelectedSeverity,
      createdAt: createdAt,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      finalSeverity: finalSeverity ?? this.finalSeverity,
    );
  }
}
