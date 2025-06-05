import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RefinePage extends StatefulWidget {
  final String userName;
  final String jobName;
  final String createdTime;
  final String status;

  const RefinePage({
    Key? key,
    required this.userName,
    required this.jobName,
    required this.createdTime,
    required this.status, required Map selectedIdleDevices,
  }) : super(key: key);

  @override
  _RefinePageState createState() => _RefinePageState();
}

class _RefinePageState extends State<RefinePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  final Map<String, List<String>> idleDeviceExamples = {
    'Gas Furnace': ['Old Gas Furnace', 'High-Efficiency Furnace', 'Low-Efficiency Furnace'],
    'Heat Pump': ['Air Source Heat Pump', 'Ground Source Heat Pump', 'Mini-Split Heat Pump'],
    'Radiant Heating': ['Radiant Floor Heating', 'Radiant Ceiling Panels', 'Radiant Wall Panels'],
    'Electric Heater': ['Baseboard Heater', 'Portable Space Heater', 'Infrared Heater'],
    'Central AC': ['Split System AC', 'Packaged AC Unit', 'Ductless AC System'],
    'Split AC': ['Multi-Split AC', 'Single-Split AC', 'Variable Refrigerant Flow AC'],
    'Window AC': ['Standard Window AC', 'Smart Window AC', 'Portable Window AC'],
    'Storage Water Heater': ['Gas Storage Water Heater', 'Electric Storage Water Heater', 'Solar Storage Water Heater'],
    'Tankless Water Heater': ['Gas Tankless Heater', 'Electric Tankless Heater', 'Condensing Tankless Heater'],
    'Solar Water Heater': ['Active Solar Heater', 'Passive Solar Heater', 'Integral Collector Storage'],
    'Refrigerator': ['Top Freezer Refrigerator', 'Bottom Freezer Refrigerator', 'Side-by-Side Refrigerator'],
    'Washing Machine': ['Front Load Washer', 'Top Load Washer', 'High-Efficiency Washer'],
    'Dishwasher': ['Standard Dishwasher', 'Drawer Dishwasher', 'Smart Dishwasher'],
    'Electric Oven': ['Convection Oven', 'Conventional Oven', 'Self-Cleaning Oven'],
    'TV': ['LED TV', 'OLED TV', 'QLED TV'],
    'Desktop Computer': ['Gaming Desktop', 'Workstation Desktop', 'Home Office Desktop'],
    'Microwave': ['Countertop Microwave', 'Built-In Microwave', 'Over-the-Range Microwave'],
    'Coffee Maker': ['Drip Coffee Maker', 'Single Serve Brewer', 'Espresso Machine'],
    'LED Bulb': ['Standard LED Bulb', 'Smart LED Bulb', 'Dimmable LED Bulb'],
    'Dimmers': ['Rotary Dimmer', 'Slide Dimmer', 'Touch Dimmer'],
    'Motion Sensors': ['Indoor Motion Sensor', 'Outdoor Motion Sensor', 'Smart Motion Sensor'],
  };

  final Map<String, GlobalKey> sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();

    idleDeviceExamples.keys.forEach((key) {
      sectionKeys[key] = GlobalKey();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToCategory(String category) {
    final context = sectionKeys[category]?.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      final viewport = RenderAbstractViewport.of(box);
      final offset = viewport!.getOffsetToReveal(box, 0.0).offset;
      _scrollController.jumpTo(offset);
    }
  }

  Widget _buildIdleDeviceContent() {
    return Row(
      children: [
        Container(
          width: 160,
          color: Colors.grey[900],
          child: ListView(
            children: idleDeviceExamples.keys.map((category) {
              return ListTile(
                dense: true,
                title: Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                onTap: () {
                  _jumpToCategory(category);
                },
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...idleDeviceExamples.entries.map((entry) {
                  return Column(
                    key: sectionKeys[entry.key],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...entry.value.map((subItem) {
                        return ListTile(
                          title: Text(
                            subItem,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Upload Image clicked (Dummy)')),
                              );
                            },
                            child: const Text('Upload Image'),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add New Category clicked (Dummy)')),
                      );
                    },
                    child: const Text('Add New Category'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Page'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detail'),
            Tab(text: 'Idle Devices'),
            Tab(text: 'Leakage Points'),
            Tab(text: 'Other Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Name: ${widget.jobName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'User: ${widget.userName}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${widget.createdTime}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${widget.status}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          _buildIdleDeviceContent(),
          Center(
            child: Text(
              'Leakage Points Content (Coming Soon)',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          Center(
            child: Text(
              'Other Items Content (Coming Soon)',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
