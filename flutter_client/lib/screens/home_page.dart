import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_client/widgets/toast.dart';
import 'package:flutter_client/screens/create_job_page.dart';
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

  List<AuditResult> jobs = [];
  List<AuditResult> filteredJobs = [];
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

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF1E1E1E),
    body: Column(
      children: [
        _buildCategorySection(),
        _buildJobToolbar(),
        _buildJobListSection(),
      ],
    ),
  );
}

Widget _buildCategorySection() {
  return Container(
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('New Job', style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _importJobs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
  );
}

Widget _buildJobToolbar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左边：全选、删除、导出、排序
            Expanded(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      const Text('Select All', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: selectedJobs.isNotEmpty ? _deleteSelectedJobs : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 162, 75, 107),
                      minimumSize: const Size(100, 32), // 调小按钮
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Delete', style: TextStyle(fontSize: 13)),
                  ),
                  ElevatedButton(
                    onPressed: selectedJobs.isNotEmpty ? _exportSelectedJobs : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 114, 189, 116),
                      
                      minimumSize: const Size(100, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Export', style: TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: 'Date (Newest)',
                      items: [
                        DropdownMenuItem(value: 'Date (Newest)', child: Text('Date (Newest)')),
                        DropdownMenuItem(value: 'Date (Oldest)', child: Text('Date (Oldest)')),
                        DropdownMenuItem(value: 'Name (A-Z)', child: Text('Name (A-Z)')),
                        DropdownMenuItem(value: 'Name (Z-A)', child: Text('Name (Z-A)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _sortJobs(value);
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16), // 左右分隔
            // 右边：过滤器 + 搜索
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: constraints.maxWidth < 500 ? 120 : 280, // 自适应
                  child: DropdownButtonFormField<String>(
                    value: 'All',
                    items: [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      ...mainCategories.map((cat) => DropdownMenuItem(
                        value: cat['title'],
                        child: Text(cat['title']!),
                      )),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _filterJobs(value);
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth < 600 ? 140 : 140, // 搜索框也自适应
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Jobs',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchJobs,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}



Widget _buildJobListSection() {
  return Expanded(
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
            job.jobName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Created: ${DateTime.parse(job.createdTime).toLocal().toString().substring(0, 19)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Job ID: ${job.jobId}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      },
    ),
  );
}


  Future<void> _loadJobs() async {
  final prefs = await SharedPreferences.getInstance();
  final jobsString = prefs.getString('audit_jobs');
  if (jobsString != null) {
    final List jobsJson = jsonDecode(jobsString);
    setState(() {
      jobs = jobsJson.map((json) => AuditResult.fromJson(json)).toList();
      jobs.sort((a, b) => DateTime.parse(b.createdTime).compareTo(DateTime.parse(a.createdTime)));
      filteredJobs = List.from(jobs);
    });
  }
}


  void _importJobs() async {
    if (!kIsWeb) {
      Toast.show(context, 'Import only supported on Web for now.');
      return;
    }
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((e) async {
        final content = reader.result as String;
        final List importedJson = jsonDecode(content);
        final List<AuditResult> importedJobs = importedJson.map((json) => AuditResult.fromJson(json)).toList();
        setState(() {
          jobs.addAll(importedJobs);
          filteredJobs = List.from(jobs);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('audit_jobs', jsonEncode(jobs.map((job) => job.toJson()).toList()));
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
    await prefs.setString('audit_jobs', jsonEncode(jobs.map((job) => job.toJson()).toList()));
  }


  void _exportSelectedJobs() {
    final selected = selectedJobs.map((i) => filteredJobs[i]).toList();
    final jsonStr = jsonEncode(selected.map((job) => job.toJson()).toList());
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
          final name = job.jobName.toLowerCase();
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

 void _showJobDetails(AuditResult job) {
  final screenSize = MediaQuery.of(context).size;  // 获取屏幕大小

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.15,   // 屏幕左右各留15%
          vertical: screenSize.height * 0.15,    // 屏幕上下各留15%
        ),
        title: Text(
          job.jobName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: screenSize.width * 0.7,    // 宽度70%
          height: screenSize.height * 0.7,  // 高度70%
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${DateTime.parse(job.createdTime).toLocal().toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (job.imageBytes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: screenSize.height * 0.35,  // 图片高度用整体高度的 35%
                    child: Image.memory(
                      job.imageBytes,
                      fit: BoxFit.contain, // 保持原比例，完整显示
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Category: ${job.category}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Equipment: ${job.equipment}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Job ID: ${job.jobId}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}



  
  void _sortJobs(String sortOption) {
  setState(() {
    if (sortOption == 'Date (Newest)') {
      filteredJobs.sort((a, b) => DateTime.parse(b.createdTime).compareTo(DateTime.parse(a.createdTime)));
    } else if (sortOption == 'Date (Oldest)') {
      filteredJobs.sort((a, b) => DateTime.parse(a.createdTime).compareTo(DateTime.parse(b.createdTime)));
    } else if (sortOption == 'Name (A-Z)') {
      filteredJobs.sort((a, b) => a.jobName.compareTo(b.jobName));
    } else if (sortOption == 'Name (Z-A)') {
      filteredJobs.sort((a, b) => b.jobName.compareTo(a.jobName));
    }
  });
}

void _filterJobs(String category) {
  setState(() {
    if (category == 'All') {
      filteredJobs = List.from(jobs);
    } else {
      filteredJobs = jobs.where((job) {
        return job.category == category; 
      }).toList();
    }
  });
}

}

