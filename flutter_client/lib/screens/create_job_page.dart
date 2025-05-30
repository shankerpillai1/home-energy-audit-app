import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuditResult {
  final String jobId;
  final String userName;
  final String jobName;
  final String mainCategory;
  final String subCategory;
  final Uint8List imageBytes;
  final DateTime createdTime;
  final String status;
  final String? suggestion;
  final String? notes;

  AuditResult({
    required this.jobId,
    required this.userName,
    required this.jobName,
    required this.mainCategory,
    required this.subCategory,
    required this.imageBytes,
    required this.createdTime,
    required this.status,
    this.suggestion,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'userName': userName,
        'jobName': jobName,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
        'imageBytes': base64Encode(imageBytes),
        'createdTime': createdTime.toIso8601String(),
        'status': status,
        'suggestion': suggestion,
        'notes': notes,
      };

  static AuditResult fromJson(Map<String, dynamic> json) => AuditResult(
        jobId: json['jobId'],
        userName: json['userName'],
        jobName: json['jobName'],
        mainCategory: json['mainCategory'],
        subCategory: json['subCategory'],
        imageBytes: base64Decode(json['imageBytes']),
        createdTime: DateTime.parse(json['createdTime']),
        status: json['status'],
        suggestion: json['suggestion'],
        notes: json['notes'],
      );
}

class CreateJobPage extends StatefulWidget {
  final String userName;

  const CreateJobPage({super.key, required this.userName});

  @override
  _CreateJobPageState createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  final Map<String, List<String>> categoryMap = {
    'Building Envelope': ['Insulation', 'Windows & Doors', 'Air Leakage', 'Roof & Attic'],
    'HVAC Systems': ['Heating Systems', 'Cooling Systems', 'Ductwork', 'Thermostats'],
    'Lighting': ['Incandescent Bulbs', 'CFLs', 'LEDs', 'Natural Lighting'],
    'Appliances & Electronics': ['Refrigerator', 'Dishwasher', 'Washer/Dryer', 'Television', 'Computers'],
    'Water Heating': ['Tank Water Heaters', 'Tankless Water Heaters', 'Water Heater Insulation', 'Pipe Insulation'],
    'Ventilation & Air Quality': ['Exhaust Fans', 'Air Purifiers', 'Humidity Control', 'Air Filters'],
    'Renewable Energy Systems': ['Solar Panels', 'Wind Turbines', 'Geothermal Systems', 'Battery Storage'],
  };

  final _formKey = GlobalKey<FormState>();

  String? jobName;
  String? selectedMainCategory;
  String? selectedSubCategory;
  Uint8List? selectedImageBytes;

  final List<AuditResult> auditResults = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _saveJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobListJson = auditResults.map((job) => job.toJson()).toList();
    await prefs.setString('audit_jobs', jsonEncode(jobListJson));
  }

  Future<void> _loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsString = prefs.getString('audit_jobs');
    if (jobsString != null) {
      final List jobsJson = jsonDecode(jobsString);
      setState(() {
        auditResults.clear();
        auditResults.addAll(jobsJson.map((json) => AuditResult.fromJson(json)).toList());
      });
    }
  }

  void _submitJob() async {
    if (_formKey.currentState!.validate() && selectedMainCategory != null && selectedSubCategory != null && selectedImageBytes != null) {
      _formKey.currentState!.save();

      final newJob = AuditResult(
        jobId: const Uuid().v4(),
        userName: widget.userName,
        jobName: jobName!,
        mainCategory: selectedMainCategory!,
        subCategory: selectedSubCategory!,
        imageBytes: selectedImageBytes!,
        createdTime: DateTime.now(),
        status: 'Pending',
        suggestion: null,
        notes: null,
      );

      auditResults.add(newJob);
      await _saveJobs();

      setState(() {
        jobName = null;
        selectedMainCategory = null;
        selectedSubCategory = null;
        selectedImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job created successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields before submitting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Job'),
          backgroundColor: Colors.blueAccent,
        ),
        backgroundColor: Colors.white,
        body: _buildCreateJobContent(context),
      );
    } else {
      return _buildCreateJobContent(context);
    }
  }

  Widget _buildCreateJobContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Step 1: Enter Job Name',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Job Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a job name' : null,
                  onSaved: (value) => jobName = value,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Step 2: Select Main Category',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMainCategory,
                  hint: const Text('Select Main Category', style: TextStyle(color: Colors.white54)),
                  dropdownColor: Colors.grey[850],
                  decoration: const InputDecoration(
                    labelText: 'Main Category',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: categoryMap.keys.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMainCategory = value;
                      selectedSubCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Step 3: Select Subcategory',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubCategory,
                  hint: const Text('Select Subcategory', style: TextStyle(color: Colors.white54)),
                  dropdownColor: Colors.grey[850],
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: (selectedMainCategory != null)
                      ? categoryMap[selectedMainCategory]!.map((String sub) {
                          return DropdownMenuItem<String>(
                            value: sub,
                            child: Text(sub),
                          );
                        }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedSubCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Step 4: Upload Image',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Image'),
                ),
                if (selectedImageBytes != null) ...[
                  const SizedBox(height: 20),
                  Image.memory(
                    selectedImageBytes!,
                    height: 200,
                  ),
                ],
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Create Job'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
