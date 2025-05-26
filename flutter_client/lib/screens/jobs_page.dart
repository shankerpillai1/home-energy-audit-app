import 'package:flutter/material.dart';
import './create_job_page.dart';

class JobsPage extends StatefulWidget {
  final String userName;
  const JobsPage({super.key, required this.userName});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  String selectedStage = 'All active stages';
  String selectedSort = 'Job ID';
  bool selectAll = false;
  String searchQuery = '';

  final List<JobData> jobs = [
    JobData('Blank Job For Testing', '5555 Walnut St. - Boulder, 80302'),
    JobData('Sample Job For Testing', '5555 Walnut Blvd. - Boulder, 80302'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredJobs = jobs
        .where((job) => job.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Redesigned Top Bar
          Container(
            height: 64,
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: selectedStage,
                                onChanged: (value) {
                                  setState(() {
                                    selectedStage = value!;
                                  });
                                },
                                items: [
                                  'All active stages',
                                  'Lead',
                                  'Audit',
                                  'Bid Proposed',
                                  'Bid Approved',
                                  'Retrofit In Progress',
                                  'Retrofit Complete',
                                  'QA',
                                  'Uncategorized',
                                  'Archived Won',
                                  'Archived Lost'
                                ].map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<String>(
                                value: selectedSort,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSort = value!;
                                  });
                                },
                                items: [
                                  'Job ID',
                                  'Last Modified',
                                  'Appointment Date',
                                  'User',
                                  'First Name',
                                  'Last Name',
                                  'Program',
                                  'Stage'
                                ].map((sort) => DropdownMenuItem(value: sort, child: Text('Sort by $sort'))).toList(),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CreateJobPage(userName: widget.userName)),

                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text('Create Job'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Welcome Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text('Welcome, ${widget.userName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),

          // Select all + Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (val) {
                        setState(() {
                          selectAll = val ?? false;
                          for (var job in jobs) {
                            job.selected = selectAll;
                          }
                        });
                      },
                    ),
                    const Text('Select all jobs', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      isDense: true,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Job List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: filteredJobs
                  .map((job) => JobCard(
                        title: job.title,
                        address: job.address,
                        selected: job.selected,
                        onChanged: (val) {
                          setState(() {
                            job.selected = val ?? false;
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class JobData {
  final String title;
  final String address;
  bool selected;

  JobData(this.title, this.address, {this.selected = false});
}

class JobCard extends StatelessWidget {
  final String title;
  final String address;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const JobCard({
    super.key,
    required this.title,
    required this.address,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Checkbox(value: selected, onChanged: onChanged),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(address),
        trailing: const Text('Thu 1 Jan, 2015\n1:00 pm', textAlign: TextAlign.right),
        isThreeLine: true,
      ),
    );
  }
}
