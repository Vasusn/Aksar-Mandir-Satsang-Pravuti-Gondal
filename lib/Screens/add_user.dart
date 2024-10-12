// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddUser extends StatefulWidget {
  const AddUser(
      {super.key, required this.userId, this.isEditing = false, this.userData});

  final int userId;
  final bool isEditing; // Add a flag for editing
  final Map<String, dynamic>? userData; // To pass existing user data

  @override
  AddUserState createState() => AddUserState();
}

class AddUserState extends State<AddUser> {
  bool isLoading = false;
  // Define controllers for each text field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _vistarController = TextEditingController();
  final TextEditingController _mandalController = TextEditingController();
  final TextEditingController _societyController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.userData != null) {
      // Set the controller values to existing data if in editing mode
      _nameController.text = widget.userData!['name'];
      _idController.text = widget.userData!['id'];
      _vistarController.text = widget.userData!['vistar'];
      _mandalController.text = widget.userData!['mandal'];
      _societyController.text = widget.userData!['society'];
      _mobileController.text = widget.userData!['mobile_number'];
      _dobController.text = widget.userData!['dob'];
    } else {
      _idController.text = "YB${NumberFormat('000').format(widget.userId + 1)}";
    }
  }

  // Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // Function to save or update user details to Firestore
  void _saveOrUpdateUser() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text,
        'id': _idController.text,
        'vistar': _vistarController.text,
        'mandal': _mandalController.text,
        'society': _societyController.text,
        'mobile_number': _mobileController.text,
        'dob': _dobController.text,
        'present': false, // Modify as needed
      };

      try {
        setState(() {
          isLoading = true;
        });
        if (widget.isEditing && widget.userData != null) {
          // Assuming user_id is a field in the collection, not the document ID
          String userId =
              widget.userData!['id']; // Assuming 'id' is stored in userData

          // Query the collection to find the document by 'id'
          var querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('id', isEqualTo: userId)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Update the first matching document
            String docId = querySnapshot.docs.first.id;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(docId)
                .update(userData);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Handle case where no document with the given 'id' is found
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User not found.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Add new user to Firestore
          await FirebaseFirestore.instance.collection('users').add(userData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Clear the form fields and pop back to the previous screen
        _clearFields();
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        // Error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save user: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
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
  Future<void> _selectDate(BuildContext context, String? date) async {
    DateFormat format = DateFormat("dd-MM-yyyy");

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.red, // Header background color
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            colorScheme: const ColorScheme.light(
              primary: Colors.grey,
              onPrimary: Colors.white,
              onSurface: Colors.red,
            ),
            dialogBackgroundColor: Colors.yellow,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Use DateFormat to correctly format the picked date
      _dobController.text = format.format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffc41a00),
        elevation: 0,
        title: Text(
          widget.isEditing ? "Edit User" : "Add User",
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'regularFont',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
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
                widget.isEditing
                    ? const SizedBox()
                    : TextFormField(
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
                        onTap: () => _selectDate(context, _dobController.text),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date of birth';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _saveOrUpdateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB32412),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          widget.isEditing ? "Update" : "Save",
                          style: const TextStyle(
                            fontSize: 22,
                            fontFamily: 'boldFont',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}














// ------------------------------------------------------------------------------
// import 'package:flutter/material.dart';
// // ignore: depend_on_referenced_packages
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class AddUser extends StatefulWidget {
//   const AddUser({super.key, required this.userId});
//   final int userId;

//   @override
//   AddUserState createState() => AddUserState();
// }

// class AddUserState extends State<AddUser> {
//   // Define controllers for each text field
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _idController = TextEditingController();
//   final TextEditingController _vistarController = TextEditingController();
//   final TextEditingController _mandalController = TextEditingController();
//   final TextEditingController _societyController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();

//   @override
//   void initState() {
//     _idController.text = "YB${NumberFormat('000').format(widget.userId + 1)}";
//     super.initState();
//   }

//   // Create a GlobalKey for the form
//   final _formKey = GlobalKey<FormState>();

//   // Function to save user details to Firestore
//   void _saveUser() async {
//     if (_formKey.currentState!.validate()) {
//       final userData = {
//         'name': _nameController.text,
//         'id': _idController.text,
//         'vistar': _vistarController.text,
//         'mandal': _mandalController.text,
//         'society': _societyController.text,
//         'mobile_number': _mobileController.text,
//         'dob': _dobController.text,
//         'present': false,
//       };

//       try {
//         await FirebaseFirestore.instance.collection('users').add(userData);
//         // ignore: use_build_context_synchronously
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('User added successfully!')),
//         );
//         _clearFields();
//         // ignore: use_build_context_synchronously
//         Navigator.pop(context);
//       } catch (e) {
//         // ignore: use_build_context_synchronously
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to add user: $e')),
//         );
//       }
//     }
//   }

//   // Function to clear text fields
//   void _clearFields() {
//     _nameController.clear();
//     _idController.clear();
//     _vistarController.clear();
//     _mandalController.clear();
//     _societyController.clear();
//     _mobileController.clear();
//     _dobController.clear();
//   }

//   // Function to open date picker for DOB
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (BuildContext context, Widget? child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             primaryColor: Colors.red, // Header background color
//             buttonTheme: const ButtonThemeData(
//                 textTheme:
//                     ButtonTextTheme.primary), // Year selected in the header
//             colorScheme: const ColorScheme.light(
//               primary: Colors.grey, // Selected date circle color
//               onPrimary: Colors.white, // Text color on selected date
//               onSurface: Colors.red, // Text color of dates
//             ),
//             dialogBackgroundColor:
//                 Colors.yellow, // Background color of the picker
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       _dobController.text = '${picked.day}-${picked.month}-${picked.year}';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xffc41a00),
//         elevation: 0,
//         title: const Text(
//           "Add User",
//           style: TextStyle(
//             fontSize: 22,
//             fontFamily: 'regularFont',
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: Form(
//           key: _formKey, // Assign the form key
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _nameController,
//                   cursorColor: Colors.black,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: 'Name *',
//                     labelStyle: TextStyle(color: Colors.black),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(
//                         color: Colors.black,
//                         width: 2.0,
//                       ),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   controller: _idController,
//                   cursorColor: Colors.black,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: 'ID *',
//                     labelStyle: TextStyle(color: Colors.black),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(
//                         color: Colors.black,
//                         width: 2.0,
//                       ),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter an ID';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 8),
                // TextFormField(
                //   controller: _vistarController,
                //   cursorColor: Colors.black,
                //   decoration: const InputDecoration(
                //     border: OutlineInputBorder(),
                //     labelText: 'Vistar',
                //     labelStyle: TextStyle(color: Colors.black),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(
                //         color: Colors.black,
                //         width: 2.0,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 8),
                // TextFormField(
                //   controller: _mandalController,
                //   cursorColor: Colors.black,
                //   decoration: const InputDecoration(
                //     border: OutlineInputBorder(),
                //     labelText: 'Mandal',
                //     labelStyle: TextStyle(color: Colors.black),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(
                //         color: Colors.black,
                //         width: 2.0,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 8),
                // TextFormField(
                //   controller: _societyController,
                //   cursorColor: Colors.black,
                //   decoration: const InputDecoration(
                //     border: OutlineInputBorder(),
                //     labelText: 'Society',
                //     labelStyle: TextStyle(color: Colors.black),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(
                //         color: Colors.black,
                //         width: 2.0,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 8),
                // TextFormField(
                //   controller: _mobileController,
                //   keyboardType: TextInputType.phone,
                //   cursorColor: Colors.black,
                //   decoration: const InputDecoration(
                //     border: OutlineInputBorder(),
                //     labelText: 'Mobile Number',
                //     labelStyle: TextStyle(color: Colors.black),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(
                //         color: Colors.black,
                //         width: 2.0,
                //       ),
                //     ),
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please enter a mobile number';
                //     }
                //     if (value.length != 10) {
                //       return 'Please enter a valid 10-digit mobile number';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 8),
                // TextFormField(
                //   controller: _dobController,
                //   cursorColor: Colors.black,
                //   readOnly: true,
                //   decoration: const InputDecoration(
                //     border: OutlineInputBorder(),
                //     labelText: 'Date of Birth',
                //     labelStyle: TextStyle(color: Colors.black),
                //     focusedBorder: OutlineInputBorder(
                //       borderSide: BorderSide(
                //         color: Colors.black,
                //         width: 2.0,
                //       ),
                //     ),
                //   ),
                //   onTap: () => _selectDate(context),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please select a date of birth';
                //     }
                //     return null;
                //   },
                // ),
//                 const SizedBox(height: 15),
//                 ElevatedButton(
//                   onPressed: _saveUser, // Call save function
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFB32412),
//                     minimumSize: const Size(double.infinity, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   child: const Text(
//                     "Save",
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
