// filepath: Mobile/lib/models/application.dart
import 'user.dart'; // Import UserInfo

enum ApplicationStatus { submitted, accepted, rejected, withdrawn }

class Application {
  final String applicationId;
  final String jobId;
  final String workerId;
  final ApplicationStatus status;
  final DateTime submissionDate;
  final UserInfo? worker; // Included via 'with' in API

  Application({
    required this.applicationId,
    required this.jobId,
    required this.workerId,
    required this.status,
    required this.submissionDate,
    this.worker,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId: json['applicationId'] as String,
      jobId: json['jobId'] as String,
      workerId: json['workerId'] as String,
      status: _parseApplicationStatus(json['status'] as String?),
      submissionDate: DateTime.parse(json['submissionDate'] as String),
       worker: json['worker'] == null ? null : UserInfo.fromJson(json['worker'] as Map<String, dynamic>),
    );
  }

   static ApplicationStatus _parseApplicationStatus(String? status) {
     switch (status?.toLowerCase()) {
       case 'accepted': return ApplicationStatus.accepted;
       case 'rejected': return ApplicationStatus.rejected;
       case 'withdrawn': return ApplicationStatus.withdrawn;
       case 'submitted':
       default:
         return ApplicationStatus.submitted;
     }
   }

   // Optional: toJson method
   Map<String, dynamic> toJson() {
     return {
       'applicationId': applicationId,
       'jobId': jobId,
       'workerId': workerId,
       'status': status.name,
       'submissionDate': submissionDate.toIso8601String(),
       // Worker info is usually read-only
     };
   }
}