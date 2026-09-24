import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';
import '../db/database_helper.dart';

class SosFormScreen extends StatefulWidget {
  const SosFormScreen({super.key});

  @override
  State<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends State<SosFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _peopleAffectedController = TextEditingController(text: '0');
  final _vulnerablePeopleController = TextEditingController(text: '0');

  String _category = 'flood';
  String _situation = 'ongoing';
  String _assistance = 'rescue';
  String _userSelectedSeverity = 'normal';

  final List<String> _categories = [
    'flood', 'fire', 'earthquake', 'storm', 'landslide', 'medical', 'supplies',
  ];
  final List<String> _situations = ['ongoing', 'escalating', 'contained'];
  final List<String> _assistanceTypes = [
    'rescue', 'medical rescue', 'water rescue', 'fire control',
    'road clearance', 'safety inspection', 'food supplies',
    'water supplies', 'blankets', 'other',
  ];
  final List<String> _severities = ['normal', 'high', 'critical'];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _peopleAffectedController.dispose();
    _vulnerablePeopleController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final id = const Uuid().v4();

    final report = Report(
      id: id,
      description: _descriptionController.text.trim(),
      category: _category,
      peopleAffected: int.tryParse(_peopleAffectedController.text) ?? 0,
      vulnerablePeople: int.tryParse(_vulnerablePeopleController.text) ?? 0,
      situation: _situation,
      assistance: _assistance,
      userSelectedSeverity: _userSelectedSeverity,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      status: 'pending_relay',
    );

    await DatabaseHelper.instance.insertReport(report);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report saved on this device. It will relay to nearby devices '
          'and sync automatically once a connection is found.',
        ),
        duration: Duration(seconds: 4),
      ),
    );

    _formKey.currentState!.reset();
    _descriptionController.clear();
    _peopleAffectedController.text = '0';
    _vulnerablePeopleController.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What is happening?',
                  hintText: 'Describe the situation in as much detail as possible',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the situation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _peopleAffectedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'People affected',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vulnerablePeopleController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vulnerable people',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _situation,
                decoration: const InputDecoration(
                  labelText: 'Situation',
                  border: OutlineInputBorder(),
                ),
                items: _situations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _situation = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _assistance,
                decoration: const InputDecoration(
                  labelText: 'Assistance needed',
                  border: OutlineInputBorder(),
                ),
                items: _assistanceTypes
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (value) => setState(() => _assistance = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _userSelectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'How severe does this feel to you?',
                  border: OutlineInputBorder(),
                ),
                items: _severities
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _userSelectedSeverity = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SUBMIT REPORT', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
