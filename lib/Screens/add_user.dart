import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  AddUserState createState() => AddUserState();
}

class AddUserState extends State<AddUser> {
  // Define controllers for each text field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _vistarController = TextEditingController();
  final TextEditingController _mandalController = TextEditingController();
  final TextEditingController _societyController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // Function to save user details to Firestore
  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text,
        'id': _idController.text,
        'vistar': _vistarController.text,
        'mandal': _mandalController.text,
        'society': _societyController.text,
        'mobile_number': _mobileController.text,
        'dob': _dobController.text,
        'present': false,
      };

      try {
        await FirebaseFirestore.instance.collection('users').add(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        _clearFields();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $e')),
        );
      }
    }
  }

  // Function to clear text fields
  void _clearFields() {
    _nameController.clear();
    _idController.clear();
    _vistarController.clear();
    _mandalController.clear();
    _societyController.clear();
    _mobileController.clear();
    _dobController.clear();
  }

  // Function to open date picker for DOB
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = '${picked.year}-${picked.month}-${picked.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffc41a00),
        elevation: 0,
        title: const Text(
          "Add User",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'regularFont',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID *',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vistarController,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Vistar',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mandalController,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mandal',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _societyController,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Society',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mobile Number',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dobController,
                cursorColor: Colors.black,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Date of Birth',
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _saveUser, // Call save function
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB32412),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
