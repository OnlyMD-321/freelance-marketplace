// filepath: Mobile/freelancers_mobile_app/lib/screens/jobs/create_job_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../providers/job_provider.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 2),
      ), // Allow up to 2 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              // primary: Theme.of(context).colorScheme.primary, // Example
              // onPrimary: Theme.of(context).colorScheme.onPrimary, // Example
            ),
            // textButtonTheme: TextButtonThemeData(...) // Example
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _submitCreateJob() async {
    // Hide keyboard first
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final title = _titleController.text;
      final description = _descriptionController.text;
      final budget = double.tryParse(
        _budgetController.text.replaceAll(',', ''),
      ); // Handle potential commas

      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      bool success = false;
      try {
        success = await jobProvider.createJob(
          title: title,
          description: description,
          budget: budget,
          deadline: _selectedDeadline,
        );
      } catch (e) {
        success = false;
        print("Error creating job: $e");
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Job created successfully!'
                : (jobProvider.errorMessage ?? 'Failed to create job.'),
          ),
          backgroundColor:
              success ? Colors.green : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    prefixIcon: Icon(Icons.title),
                    // Uses theme's inputDecorationTheme
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Job Description',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                    // Uses theme's inputDecorationTheme
                  ),
                  maxLines: 6,
                  minLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction:
                      TextInputAction
                          .newline, // Allows newline in multiline field
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget (Optional)',
                    prefixIcon: Icon(Icons.attach_money),
                    // Consider adding prefixText: '\$ ' if appropriate
                    // prefixText: '\$ ',
                    // Uses theme's inputDecorationTheme
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // validator: (value) { // Optional: Validate format if needed
                  //   if (value != null && value.isNotEmpty && double.tryParse(value.replaceAll(',', '')) == null) {
                  //     return 'Please enter a valid number';
                  //   }
                  //   return null;
                  // },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Deadline (Optional)',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ), // Adjust padding
                    // Apply similar border/fill from theme
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDeadline == null
                            ? 'Not Set'
                            : DateFormat.yMd().format(
                              _selectedDeadline!.toLocal(),
                            ), // Use intl format
                        style: textTheme.bodyLarge?.copyWith(
                          color:
                              _selectedDeadline == null
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDeadline(context),
                        child: Text(
                          _selectedDeadline == null
                              ? 'Set Date'
                              : 'Change Date',
                        ),
                        // Uses theme's textButtonTheme
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                      icon: const Icon(Icons.post_add),
                      onPressed: _submitCreateJob,
                      label: const Text('Post Job'),
                      // Uses theme's elevatedButtonTheme
                      // style: ElevatedButton.styleFrom(padding: ...) // Adjust padding if needed
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
