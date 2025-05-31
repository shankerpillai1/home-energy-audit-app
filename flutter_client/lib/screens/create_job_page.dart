// create_job_page.dart (final version: Dropdown + Autocomplete with default list)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';

class CreateJobPage extends StatefulWidget {
  final String userName;

  const CreateJobPage({Key? key, required this.userName}) : super(key: key);

  @override
  _CreateJobPageState createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  String? selectedCategory;
  String? selectedSubcategory;
  File? selectedImage;
  final TextEditingController subcategoryController = TextEditingController();

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

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedImage = File(result.files.single.path!);
      });
    }
  }

  void submitJob() {
    if (selectedImage == null || selectedCategory == null || subcategoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job Created Successfully!')),
    );

    setState(() {
      selectedImage = null;
      selectedCategory = null;
      subcategoryController.clear();
    });
  }

  @override
  void dispose() {
    subcategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Image', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Center(
              child: selectedImage == null
                  ? ElevatedButton(
                      onPressed: pickImage,
                      child: Text('Pick Image'),
                    )
                  : Image.file(selectedImage!, height: 200),
            ),
            SizedBox(height: 20),

            // Main Category: Only selection
            DropdownSearch<String>(
              popupProps: PopupProps.menu(
                showSearchBox: false,
              ),
              items: categoryMap.keys.toList(),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Select Main Category",
                  border: OutlineInputBorder(),
                ),
              ),
              selectedItem: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  subcategoryController.clear();
                });
              },
            ),
            SizedBox(height: 20),

            // Subcategory: Autocomplete input with full list default
            if (selectedCategory != null)
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final options = getSubcategories(selectedCategory);
                  if (textEditingValue.text.isEmpty) {
                    return options;
                  }
                  return options.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    subcategoryController.text = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  controller.text = subcategoryController.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: "Subcategory (select or type)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        subcategoryController.text = value;
                      });
                    },
                  );
                },
              ),

            SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: submitJob,
                child: Text('Create Job'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
