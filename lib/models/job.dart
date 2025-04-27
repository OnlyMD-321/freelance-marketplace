// filepath: Mobile/lib/models/job.dart
import 'user.dart'; // Import UserInfo

enum JobStatus { open, inProgress, completed, cancelled }

class Job {
  final String jobId;
  final String clientId;
  final String title;
  final String description;
  final double? budget; // Optional budget
  final JobStatus status;
  final DateTime postedDate;
  final DateTime? deadline; // Optional deadline
  final UserInfo? client; // Included via 'with' in API

  Job({
    required this.jobId,
    required this.clientId,
    required this.title,
    required this.description,
    this.budget,
    required this.status,
    required this.postedDate,
    this.deadline,
    this.client,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['jobId'] as String,
      clientId: json['clientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num?)?.toDouble(),
      status: _parseJobStatus(json['status'] as String?),
      postedDate: DateTime.parse(json['postedDate'] as String),
      deadline: json['deadline'] == null ? null : DateTime.parse(json['deadline'] as String),
      client: json['client'] == null ? null : UserInfo.fromJson(json['client'] as Map<String, dynamic>),
    );
  }

  static JobStatus _parseJobStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'inprogress': return JobStatus.inProgress;
      case 'completed': return JobStatus.completed;
      case 'cancelled': return JobStatus.cancelled;
      case 'open':
      default:
        return JobStatus.open;
    }
  }

   // Optional: toJson method
   Map<String, dynamic> toJson() {
     return {
       'jobId': jobId,
       'clientId': clientId,
       'title': title,
       'description': description,
       'budget': budget,
       'status': status.name, // Assumes Dart 3 enum naming
       'postedDate': postedDate.toIso8601String(),
       'deadline': deadline?.toIso8601String(),
       // Client info is usually read-only from API, not sent back in this format
     };
   }
}