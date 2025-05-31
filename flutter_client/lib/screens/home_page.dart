import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_client/widgets/toast.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  final String userName;
  final void Function(String route) onNavigate;

  const HomePage({super.key, required this.userName, required this.onNavigate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  bool selectAll = false;
  Set<int> selectedJobs = {};
  TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> mainCategories = [
    {
      'title': 'Device End-Use',
      'description': 'Appliances like air conditioners, refrigerators.',
      'examples': 'AC, TV, Refrigerator'
    },
    {
      'title': 'Building Envelope',
      'description': 'Walls, windows, doors, insulation.',
      'examples': 'Insulation, Low-E Windows'
    },
    {
      'title': 'Air Leakage / Infiltration',
      'description': 'Gaps and cracks allowing air flow.',
      'examples': 'Door Gaps, Window Cracks'
    },
    {
      'title': 'Indoor Air Quality & Ventilation',
      'description': 'Ventilation systems, air purifiers.',
      'examples': 'HRV, ERV, Air Purifier'
    },
    {
      'title': 'Renewable & Alternative Energy Systems',
      'description': 'Solar, geothermal, wind energy systems.',
      'examples': 'Solar PV, Wind Turbine'
    },
    {
      'title': 'Water Use & Efficiency',
      'description': 'Water heaters, efficient fixtures.',
      'examples': 'Low-flow Showerhead, Tankless Heater'
    },
    {
      'title': 'Occupant Behavior & Usage Patterns',
      'description': 'Energy use habits and schedules.',
      'examples': 'Smart Thermostat, Usage Monitoring'
    },
    {
      'title': 'Health & Safety',
      'description': 'Smoke alarms, CO detectors.',
      'examples': 'Smoke Detector, CO Alarm'
    },
  ];

  bool showCategories = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsString = prefs.getString('audit_jobs');
    if (jobsString != null) {
      final List jobsJson = jsonDecode(jobsString);
      setState(() {
        jobs = jobsJson.cast<Map<String, dynamic>>();
        jobs.sort((a, b) => DateTime.parse(b['createdTime']).compareTo(DateTime.parse(a['createdTime'])));
        filteredJobs = List.from(jobs);
      });
    }
  }

  void _importJobs() {
    if (!kIsWeb) {
      Toast.show(context, 'Import only supported on Web for now.');
      return;
    }
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((e) async {
        final content = reader.result as String;
        final List importedJobs = jsonDecode(content);
        setState(() {
          jobs.addAll(importedJobs.cast<Map<String, dynamic>>());
          filteredJobs = List.from(jobs);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('audit_jobs', jsonEncode(jobs));
        Toast.show(context, 'Import Successful!');
      });
    });
  }


  void _toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      if (selectAll) {
        selectedJobs = Set<int>.from(List.generate(filteredJobs.length, (index) => index));
      } else {
        selectedJobs.clear();
      }
    });
  }

  void _deleteSelectedJobs() async {
    setState(() {
      final jobsToDelete = selectedJobs.map((i) => filteredJobs[i]).toList();
      jobs.removeWhere((job) => jobsToDelete.contains(job));
      filteredJobs.removeWhere((job) => jobsToDelete.contains(job));
      selectedJobs.clear();
      selectAll = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audit_jobs', jsonEncode(jobs));
  }

  void _exportSelectedJobs() {
    final selected = selectedJobs.map((i) => filteredJobs[i]).toList();
    final jsonStr = jsonEncode(selected);
    final blob = html.Blob([jsonStr]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'selected_jobs.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _searchJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredJobs = List.from(jobs);
      } else {
        filteredJobs = jobs.where((job) {
          final name = job['jobName']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSelectJob(int index) {
    setState(() {
      if (selectedJobs.contains(index)) {
        selectedJobs.remove(index);
      } else {
        selectedJobs.add(index);
      }
      selectAll = selectedJobs.length == filteredJobs.length;
    });
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(job['jobName'] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Job ID: ${job['jobId'] ?? ''}'),
                const SizedBox(height: 10),
                Text('Created: ${job['createdTime'] != null ? DateTime.parse(job['createdTime']).toLocal().toString().substring(0, 19) : ''}'),
                const SizedBox(height: 10),
                Text('Details: ${jsonEncode(job)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Column(
        children: [
          Container(
            height: showCategories ? MediaQuery.of(context).size.height * 0.6 : 80,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => widget.onNavigate('/dashboard/create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text('New Job', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _importJobs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: const Text('Import Jobs', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Expand/Collapse Categories', style: TextStyle(color: Colors.white, fontSize: 14)),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showCategories = !showCategories;
                            });
                          },
                          icon: Icon(
                            showCategories ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showCategories) ...[
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double maxCardWidth = 300;
                        int crossAxisCount = (constraints.maxWidth / maxCardWidth).floor().clamp(2, 4);
                        double cardWidth = constraints.maxWidth / crossAxisCount - 12;
                        double titleFontSize = (cardWidth * 0.065).clamp(9.0, 14.0);
                        double descFontSize = (cardWidth * 0.055).clamp(8.0, 13.0);
                        double exampleFontSize = (cardWidth * 0.045).clamp(8.0, 13.0);
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 440,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.95,
                          ),
                          itemCount: mainCategories.length,
                          itemBuilder: (context, index) {
                            final category = mainCategories[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              color: const Color(0xFF2C2C2C),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category['title']!.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      category['description']!,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: descFontSize,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      category['examples']!,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: exampleFontSize,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      const Text('Select All', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: selectedJobs.isNotEmpty ? _deleteSelectedJobs : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          minimumSize: const Size(120, 36),
                        ),
                        child: const Text('Delete Selected', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: selectedJobs.isNotEmpty ? _exportSelectedJobs : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(120, 36),
                        ),
                        child: const Text('Export Selected', style: TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          width: 250,
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search Jobs',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: _searchJobs,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return ListTile(
                        onTap: () => _showJobDetails(job),
                        leading: Checkbox(
                          value: selectedJobs.contains(index),
                          onChanged: (_) => _toggleSelectJob(index),
                          activeColor: Colors.blueAccent,
                        ),
                        title: Text(
                          job['jobName'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created: ${job['createdTime'] != null ? DateTime.parse(job['createdTime']).toLocal().toString().substring(0, 19) : ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'Job ID: ${job['jobId'] ?? ''}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
