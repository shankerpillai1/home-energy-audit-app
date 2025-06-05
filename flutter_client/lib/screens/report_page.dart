import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ReportPage extends StatefulWidget {
  final String userName;
  final String jobName;
  final String createdTime;
  final String status;

  const ReportPage({
    Key? key,
    required this.userName,
    required this.jobName,
    required this.createdTime,
    required this.status,
  }) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {
    'Job Info': GlobalKey(),
    'Idle Devices': GlobalKey(),
    'Leakage Points': GlobalKey(),
    'Other Items': GlobalKey(),
  };

  final Map<String, List<String>> idleDeviceExamples = {
    'Gas Furnace': ['Old Gas Furnace', 'High-Efficiency Furnace', 'Low-Efficiency Furnace'],
    'Heat Pump': ['Air Source Heat Pump', 'Ground Source Heat Pump', 'Mini-Split Heat Pump'],
    'Radiant Heating': ['Radiant Floor Heating', 'Radiant Ceiling Panels', 'Radiant Wall Panels'],
  };

  void _jumpToSection(String section) {
    final context = sectionKeys[section]?.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      final viewport = RenderAbstractViewport.of(box);
      final offset = viewport!.getOffsetToReveal(box, 0.0).offset;
      _scrollController.jumpTo(offset);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      key: sectionKeys[title],
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildIdleDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: idleDeviceExamples.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ...entry.value.map((subItem) => Text('- $subItem', style: const TextStyle(color: Colors.white))).toList(),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Report')),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.grey[900],
            child: ListView(
              children: [
                ExpansionTile(
                  title: const Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 14)),
                  children: sectionKeys.keys.map((section) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        section,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      onTap: () => _jumpToSection(section),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Job Info'),
                  Text('Job Name: ${widget.jobName}', style: const TextStyle(color: Colors.white)),
                  Text('User: ${widget.userName}', style: const TextStyle(color: Colors.white)),
                  Text('Created: ${widget.createdTime}', style: const TextStyle(color: Colors.white)),
                  Text('Status: ${widget.status}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Idle Devices'),
                  _buildIdleDevices(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Leakage Points'),
                  const Text('Leakage Points Details Here...', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Other Items'),
                  const Text('Other Items Details Here...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
