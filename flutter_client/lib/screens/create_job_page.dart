import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateJobPage extends StatefulWidget {
  final String userName;
  const CreateJobPage({super.key, required this.userName});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  String selectedStage = 'Lead';
  String jobType = 'Blank';
  final TextEditingController dateController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  String selectedState = 'CA';
  String homeStatus = 'Renter';

  final List<String> stages = [
    'Lead', 'Audit', 'Bid Proposed', 'Bid Approved', 'Retrofit In Progress',
    'Retrofit Complete', 'QA', 'Uncategorized', 'Archived Won', 'Archived Lost'
  ];

  final List<String> states = ['CA', 'CO', 'NY', 'TX', 'FL'];

  @override
  void initState() {
    super.initState();
    dateController.addListener(() {
      final text = dateController.text;
      final formatted = _autoFormatDateTime(text);
      if (formatted != text) {
        dateController.value = dateController.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  String _autoFormatDateTime(String input) {
    final buffer = StringBuffer();
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 2) buffer.write(digits.substring(0, 2) + '/');
    if (digits.length >= 4) buffer.write(digits.substring(2, 4) + '/');
    if (digits.length >= 8) buffer.write(digits.substring(4, 8) + ', ');
    if (digits.length >= 10) buffer.write(digits.substring(8, 10) + ':');
    if (digits.length >= 12) buffer.write(digits.substring(10, 12) + ' ');
    if (digits.length > 12) buffer.write(digits.substring(12));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create a Job - ${widget.userName}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildLabel('Stage:'),
              _styledDropdown(selectedStage, stages, (value) {
                setState(() {
                  selectedStage = value!;
                });
              }),
              const SizedBox(height: 16),

              _buildLabel('Start With:'),
              Row(
                children: [
                  _styledChip('Blank', jobType),
                  const SizedBox(width: 8),
                  _styledChip('Template', jobType),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Appointment Date & Time:'),
              TextField(
                controller: dateController,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:/, AMPMapm]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                decoration: const InputDecoration(hintText: 'MM/DD/YYYY, HH:MM AM/PM'),
              ),
              const SizedBox(height: 16),

              _buildLabel('First Name:'),
              TextField(controller: firstNameController),
              const SizedBox(height: 16),

              _buildLabel('Last Name:'),
              TextField(controller: lastNameController),
              const SizedBox(height: 16),

              _buildLabel('Email:'),
              TextField(controller: emailController),
              const SizedBox(height: 16),

              _buildLabel('Phone:'),
              TextField(controller: phoneController),
              const SizedBox(height: 16),

              _buildLabel('Address 1:'),
              TextField(controller: address1Controller),
              const SizedBox(height: 16),

              _buildLabel('Address 2:'),
              TextField(controller: address2Controller),
              const SizedBox(height: 16),

              _buildLabel('City:'),
              TextField(controller: cityController),
              const SizedBox(height: 16),

              _buildLabel('State:'),
              _styledDropdown(selectedState, states, (value) {
                setState(() {
                  selectedState = value!;
                });
              }),
              const SizedBox(height: 16),

              _buildLabel('Zip:'),
              TextField(controller: zipController),
              const SizedBox(height: 16),

              _buildLabel('Rent or Own:'),
              Row(
                children: [
                  _styledChip('Renter', homeStatus),
                  const SizedBox(width: 8),
                  _styledChip('Owner', homeStatus),
                ],
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/input');
                },
                child: const Text('Create new job'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget _styledDropdown(String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      borderRadius: BorderRadius.circular(6),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _styledChip(String label, String groupValue) {
    final bool selected = label == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => homeStatus = label),
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
    );
  }
}
