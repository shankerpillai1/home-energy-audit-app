import 'package:flutter/material.dart';

class HomeInfoScreen extends StatefulWidget {
  @override
  _HomeInfoScreenState createState() => _HomeInfoScreenState();
}

class _HomeInfoScreenState extends State<HomeInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedYear;
  String? selectedType;

  final areaController = TextEditingController();
  final floorsController = TextEditingController();
  final zipController = TextEditingController();

  final List<String> yearOptions = List.generate(100, (i) => '${2024 - i}');
  final List<String> typeOptions = ['Detached', 'Apartment', 'Townhouse', 'Other'];

  @override
  void dispose() {
    areaController.dispose();
    floorsController.dispose();
    zipController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print('Year: $selectedYear');
      print('Area: ${areaController.text}');
      print('Floors: ${floorsController.text}');
      print('Type: $selectedType');
      print('Zip: ${zipController.text}');
      // TODO: 跳转到下一页或保存数据
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Home Information')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Year Built'),
                value: selectedYear,
                items: yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (value) => setState(() => selectedYear = value),
                validator: (value) => value == null ? 'Please select a year' : null,
              ),
              TextFormField(
                controller: areaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Home Area (sqm)'),
                validator: (value) => value!.isEmpty ? 'Please enter area' : null,
              ),
              TextFormField(
                controller: floorsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Number of Floors'),
                validator: (value) => value!.isEmpty ? 'Please enter number of floors' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Home Type'),
                value: selectedType,
                items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (value) => setState(() => selectedType = value),
                validator: (value) => value == null ? 'Please select type' : null,
              ),
              TextFormField(
                controller: zipController,
                decoration: InputDecoration(labelText: 'Postal Code'),
                validator: (value) => value!.isEmpty ? 'Please enter zip code' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
