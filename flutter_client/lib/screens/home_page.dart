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

   void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job['jobName'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        job['mainCategory'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (job['imageBytes'] != null)
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(job['imageBytes'])),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Sub Category: ${job['subCategory'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Suggestion:',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    job['feedback'] ?? 'No suggestion yet',
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final toDelete = selectedJobs.map((i) => filteredJobs[i]['jobId']).toSet();
      jobs.removeWhere((job) => toDelete.contains(job['jobId']));
      filteredJobs = List.from(jobs);
      selectedJobs.clear();
      selectAll = false;
    });
    final jobListJson = jobs.map((job) => job).toList();
    await prefs.setString('audit_jobs', jsonEncode(jobListJson));
    Toast.show(context, 'Deleted Successfully!');
  }

  void _exportSelectedJobs() {
    if (selectedJobs.isEmpty) {
      Toast.show(context, 'No jobs selected for export!');
      return;
    }
    final selected = selectedJobs.map((i) => filteredJobs[i]).toList();
    final jsonStr = jsonEncode(selected);

    if (kIsWeb) {
      final bytes = utf8.encode(jsonStr);
      final blob = html.Blob([bytes]);
      final now = DateTime.now();
      final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
      final fileName = "${widget.userName}_exported_jobs_$timestamp.json";
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      Toast.show(context, 'Export only supported on Web for now.');
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
          jobs.sort((a, b) => DateTime.parse(b['createdTime']).compareTo(DateTime.parse(a['createdTime'])));
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
        selectedJobs = {for (int i = 0; i < filteredJobs.length; i++) i};
      } else {
        selectedJobs.clear();
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
    });
  }

  void _searchJobs(String query) {
    setState(() {
      filteredJobs = jobs
          .where((job) => job['jobName']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      selectedJobs.clear();
      selectAll = false;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.2,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => widget.onNavigate('/dashboard/create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('New Job', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _importJobs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Import Jobs', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                const Text('Select All', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: selectedJobs.isNotEmpty ? _deleteSelectedJobs : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    minimumSize: const Size(140, 40),
                  ),
                  child: const Text('Delete Selected', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: selectedJobs.isNotEmpty ? _exportSelectedJobs : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(140, 40),
                  ),
                  child: const Text('Export Selected', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    width: 250,
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search Jobs',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${job['createdTime'] != null ? DateTime.parse(job['createdTime']).toLocal().toString().substring(0, 19) : ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Job ID: ${job['jobId'] ?? ''}',
                        style: const TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
