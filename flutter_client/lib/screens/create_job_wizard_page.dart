import 'package:flutter/material.dart';

class CreateJobWizardPage extends StatefulWidget {
  final VoidCallback onBack;

  const CreateJobWizardPage({Key? key, required this.onBack}) : super(key: key);

  @override
  _CreateJobWizardPageState createState() => _CreateJobWizardPageState();
}

class _CreateJobWizardPageState extends State<CreateJobWizardPage> {
  int _currentStep = 0;

  final TextEditingController _jobNameController = TextEditingController();
  final Set<String> _selectedIdleDevices = {};
  final Set<String> _selectedIdleSubItems = {};
  final Set<String> _selectedLeakageCategories = {};
  final Set<String> _selectedLeakageItems = {};

  final Map<String, List<String>> idleDeviceExamples = {
    'Refrigerator or Freezer': ['Old Fridge', 'Double Door Fridge', 'Mini Fridge'],
    'Television (any type of TV)': ['LCD TV', 'LED TV', 'CRT TV'],
    'Desktop Computer (not a laptop)': ['Gaming PC', 'Office PC', 'Server PC'],
    'Whole-Home Backup Battery': ['Tesla Powerwall', 'LG Chem RESU', 'Sonnen Eco'],
    'Whole-House Lighting System': ['Smart Lighting Hub', 'Dimmer Panel', 'Wall Controllers'],
    'Undersized AC Unit': ['Old Window AC', 'Portable AC', 'Mini-split AC'],
    'Heated Tile Floor': ['Bathroom Floor Heating', 'Kitchen Floor Heating', 'Living Room Floor Heating'],
    'Large Security System': ['Multiple CCTV Cameras', 'Motion Sensors', 'Alarm Panels'],
    'Wine Cellar': ['Walk-in Wine Closet', 'Underground Wine Room', 'Climate Controlled Wine Storage'],
    'Continuous Heat Pump': ['Old Heat Pump', 'Small Capacity Heat Pump', 'Noisy Heat Pump'],
  };

  final Map<String, List<Map<String, String>>> leakagePoints = {
    'Doors': [
      {'name': 'Door Gaps', 'desc': 'Can cause air leakage and energy loss.'},
      {'name': 'Poor Seals', 'desc': 'Degraded door seals.'},
    ],
    'Windows': [
      {'name': 'Window Cracks', 'desc': 'Poor sealing wastes heating/cooling.'},
      {'name': 'Frame Gaps', 'desc': 'Gaps between window frame and wall.'},
    ],
    'Roofs': [
      {'name': 'Attic Leaks', 'desc': 'Hot/cold air escapes easily through attic.'},
      {'name': 'Roof Gaps', 'desc': 'Structural gaps in roofing.'},
    ],
  };

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitJob() {
    widget.onBack();
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIdleDeviceSelect() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.7,
      child: SingleChildScrollView(
        child: Column(
          children: idleDeviceExamples.keys.map((item) {
            final isSelected = _selectedIdleDevices.contains(item);
            return CheckboxListTile(
              title: Text(item),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedIdleDevices.add(item);
                  } else {
                    _selectedIdleDevices.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIdleSubItemSelect() {
    return Column(
      children: _selectedIdleDevices.expand((item) {
        final examples = idleDeviceExamples[item] ?? [];
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(item, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ...examples.map((subItem) {
            final isSelected = _selectedIdleSubItems.contains(subItem);
            return CheckboxListTile(
              title: Text(subItem),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedIdleSubItems.add(subItem);
                  } else {
                    _selectedIdleSubItems.remove(subItem);
                  }
                });
              },
            );
          }).toList(),
        ];
      }).toList(),
    );
  }

  Widget _buildLeakageCategorySelect() {
    return Column(
      children: leakagePoints.keys.map((cat) {
        final isSelected = _selectedLeakageCategories.contains(cat);
        return CheckboxListTile(
          title: Text(cat),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedLeakageCategories.add(cat);
              } else {
                _selectedLeakageCategories.remove(cat);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLeakageSubcategorySelect() {
    List<Widget> widgets = [];
    for (var cat in _selectedLeakageCategories) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(cat, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );
      widgets.addAll(
        leakagePoints[cat]!.map((item) {
          final isSelected = _selectedLeakageItems.contains(item['name']);
          return CheckboxListTile(
            title: Text(item['name']!),
            subtitle: Text(item['desc']!),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedLeakageItems.add(item['name']!);
                } else {
                  _selectedLeakageItems.remove(item['name']!);
                }
              });
            },
          );
        }).toList(),
      );
    }
    return Column(children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> steps = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Step 1: Enter Job Name', 'Give your audit task a clear and descriptive name.'),
          Center(
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: _jobNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Job Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent),
                  ),
                  filled: true,
                  fillColor: Color(0xFF2C2C2C),
                ),
              ),
            ),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Step 2: Select Idle Devices', 'Choose devices that are idle but still consume energy.'),
          _buildIdleDeviceSelect(),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Step 3: Select Sub Items of Idle Devices', 'Select detailed sub-items under chosen idle devices.'),
          _buildIdleSubItemSelect(),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Step 4: Select Leakage Categories', 'Identify potential areas for air leakage.'),
          _buildLeakageCategorySelect(),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepTitle('Step 5: Select Leakage Subcategories', 'Select detailed leakage points under chosen categories.'),
          _buildLeakageSubcategorySelect(),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Job (Step ${_currentStep + 1}/${steps.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / steps.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: steps[_currentStep],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_currentStep > 0)
              ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text('Back'),
              ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _currentStep < steps.length - 1 ? _nextStep : _submitJob,
              child: Text(_currentStep < steps.length - 1 ? 'Next' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
