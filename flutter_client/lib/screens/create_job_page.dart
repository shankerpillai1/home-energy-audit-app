import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuditResult {
  final String jobId;
  final String userName;
  final String jobName;
  final String category;
  final String equipment;
  final Uint8List imageBytes;
  final String createdTime;
  final String status;
  final String? suggestion;
  final String? notes;

  AuditResult({
    required this.jobId,
    required this.userName,
    required this.jobName,
    required this.category,
    required this.equipment,
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
        'category': category,
        'equipment': equipment,
        'imageBytes': base64Encode(imageBytes),
        'createdTime': createdTime,
        'status': status,
        'suggestion': suggestion,
        'notes': notes,
      };

  static AuditResult fromJson(Map<String, dynamic> json) => AuditResult(
        jobId: json['jobId'],
        userName: json['userName'],
        jobName: json['jobName'],
        category: json['category'],
        equipment: json['equipment'],
        imageBytes: base64Decode(json['imageBytes']),
        createdTime: json['createdTime'],
        status: json['status'],
        suggestion: json['suggestion'],
        notes: json['notes'],
      );
}

class CreateJobPage extends StatefulWidget {
  final String userName;
  final VoidCallback onBack; // 返回按钮

  const CreateJobPage({Key? key, required this.userName, required this.onBack}) : super(key: key);

  @override
  _CreateJobPageState createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  String? jobName;
  String? selectedMainCategory;
  String? selectedSubCategory;
  Uint8List? selectedImageBytes;
  final List<AuditResult> auditResults = [];

  final Map<String, List<String>> categoryMap = {
    'Device End-Use': [
      'Gas Furnace', 'Heat Pump', 'Radiant Heating', 'Electric Heater',
      'Central AC', 'Split AC', 'Window AC',
      'Storage Water Heater', 'Tankless Water Heater', 'Solar Water Heater',
      'Refrigerator', 'Washing Machine', 'Dishwasher', 'Electric Oven',
      'TV', 'Desktop Computer', 'Microwave', 'Coffee Maker', 'LED Bulb',
      'Dimmers', 'Motion Sensors'
    ],
    'Building Envelope': [
      'Wall Insulation', 'Roof Insulation', 'Window - Double Pane',
      'Window - Low-E Glass', 'Weatherstripping', 'Caulking',
      'Siding Material', 'Thermal Bridges'
    ],
    'Air Leakage / Infiltration': [
      'Door Threshold Gaps', 'Window Frame Gaps', 'Duct Penetration Gaps',
      'Wall Cracks', 'Attic Leaks'
    ],
    'Indoor Air Quality & Ventilation': [
      'Exhaust Fans', 'Heat Recovery Ventilator',
      'Air Purifiers', 'HVAC Filters', 'CO2 Sensors', 'PM Monitors'
    ],
    'Renewable & Alternative Energy Systems': [
      'Solar PV', 'Solar Thermal', 'Geothermal Heat Pump', 'Wind Turbine', 'EV Charger'
    ],
    'Water Use & Efficiency': [
      'Hot Water Pipe Insulation', 'Low-Flow Showerhead', 'Efficient Toilet',
      'Leak Detection', 'Outdoor Irrigation'
    ],
    'Occupant Behavior & Usage Patterns': [
      'Thermostat Settings', 'Peak/Off-Peak Usage', 'Lighting Practices',
      'Standby Loads'
    ],
    'Health & Safety': [
      'Combustion Safety', 'Smoke/CO Alarms', 'Electrical Panels', 'Gas Leak Detection'
    ],
    'Other': ['Other']
  };

  List<String> getSubcategories(String? category) {
    if (category != null && categoryMap.containsKey(category)) {
      return categoryMap[category]!;
    }
    return [];
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          selectedImageBytes = result.files.single.bytes!;
        });
      }
    } catch (_) {}
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
        auditResults.addAll(
          jobsJson.map((json) => AuditResult.fromJson(json)).toList(),
        );
      });
    }
  }

  void _submitJob() async {
    if (_formKey.currentState!.validate() &&
        selectedMainCategory != null &&
        selectedSubCategory != null &&
        selectedImageBytes != null) {
      _formKey.currentState!.save();

      final newJob = AuditResult(
        jobId: const Uuid().v4(),
        userName: widget.userName,
        jobName: jobName!,
        category: selectedMainCategory!,
        equipment: selectedSubCategory!,
        imageBytes: selectedImageBytes!,
        createdTime: DateTime.now().toIso8601String(),
        status: 'Pending',
        suggestion: 'Suggestion pending...',
        notes: null,
      );

      auditResults.add(newJob);
      await _saveJobs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job created successfully!')),
      );

      widget.onBack(); // 提交后返回
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields before submitting.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          color: Colors.grey[900],
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    const Text('Create New Job', style: TextStyle(fontSize: 24, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStepTitle('Upload Image'),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Image'),
                ),
                if (selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Image.memory(selectedImageBytes!, height: 200),
                  ),
                _buildStepTitle('Step 1: Enter Job Name'),
                TextFormField(
                  decoration: _inputDecoration('Job Name'),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a job name' : null,
                  onSaved: (value) => jobName = value,
                ),
                _buildStepTitle('Step 2: Select Main Category'),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Select Main Category'),
                  value: selectedMainCategory,
                  items: categoryMap.keys.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMainCategory = value;
                      selectedSubCategory = null;
                    });
                  },
                  dropdownColor: const Color(0xFF2C2C2C),
                ),
                const SizedBox(height: 20),
                if (selectedMainCategory != null)
                  SizedBox(
                    width: 400, // 输入框宽度
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final options = getSubcategories(selectedMainCategory);
                        if (textEditingValue.text.isEmpty) {
                          return options;
                        }
                        return options.where((option) =>
                            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        controller.text = selectedSubCategory ?? '';
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: _inputDecoration('Select or Enter Subcategory'),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            selectedSubCategory = value;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: const Color(0xFF2C2C2C),
                            elevation: 4.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 400,
                                maxHeight: 200,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option, style: const TextStyle(color: Colors.white)),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedSubCategory = selection;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Create Job'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(title, style: const TextStyle(fontSize: 24, color: Colors.white)),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.lightBlueAccent)),
      );
}
