// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:aksar_mandir_gondal/Screens/login_screen.dart';
import 'package:aksar_mandir_gondal/Screens/user_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> addAttendanceWithUsers(
      BuildContext context, DateTime selectedDate) async {
    try {
      // Format the selected date to check in Firestore
      String formattedDate = DateFormat('EEEE, MMM d').format(selectedDate);

      // Check if attendance for the selected date already exists
      QuerySnapshot existingAttendance = await FirebaseFirestore.instance
          .collection('attendence')
          .where('date', isEqualTo: formattedDate)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        // Attendance for the selected date already exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance for this date is already taken!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return; // Exit the function to prevent further execution
      }

      // Retrieve all user documents from Firestore
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(); // Fetch the users once

      // Map user documents to a list of user data (including the ID and other fields)
      List<Map<String, dynamic>> usersData = userSnapshot.docs.map((doc) {
        return {
          'id': doc.id, // User ID
          ...doc.data() as Map<String,
              dynamic> // Spread the rest of the user document data
        };
      }).toList();

      // Add attendance with the full user array
      await FirebaseFirestore.instance.collection('attendence').add({
        'date': formattedDate, // Store formatted date
        'user_array': usersData, // Store the complete user data
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('Attendance added successfully!');
    } catch (e) {
      print('Error adding attendance: $e');
    }
  }
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate =
        _findNextSunday(_selectedDate); // Start with the nearest Sunday
    _today = _findNextSunday(_today); // Align today with the nearest Sunday
  }

  // Function to find the next Sunday from a given date
  DateTime _findNextSunday(DateTime date) {
    while (date.weekday != DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  // Navigate to the previous Sunday
  void _goToPreviousSunday() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    });
  }

  // Navigate to the next Sunday if it's not a future date
  void _goToNextSunday() {
    if (_selectedDate.add(const Duration(days: 7)).isBefore(_today) ||
        _selectedDate.add(const Duration(days: 7)).isAtSameMomentAs(_today)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      });
    }
  }

  // Fetch users based on the selected date
  Stream<QuerySnapshot> _getUsersForSelectedDate() {
    String formattedDate = DateFormat('EEEE, MMM d').format(_selectedDate);
    return FirebaseFirestore.instance
        .collection('attendence')
        .where('date', isEqualTo: formattedDate)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffc41a00),
        elevation: 0,
        title: const Text(
          "Aksar Mandir Satsang Pravuti",
          style: TextStyle(fontSize: 22, fontFamily: 'regularFont'),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildDateRow(), // The row that includes date and navigation buttons
          const SizedBox(height: 10),
          _buildSearchBar(), // The search bar
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUsersForSelectedDate(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final attendanceDocs = snapshot.data!.docs;

                if (attendanceDocs.isEmpty) {
                  return const Center(
                    child: Text('No attendance records found for this date.'),
                  );
                }

                final usersData = attendanceDocs.first['user_array'] as List;
                return ListView.builder(
                  itemCount: usersData.length,
                  itemBuilder: (context, index) {
                    final user = usersData[index];
                    return ContactCard(
                      name: user['name'] ?? 'N/A',
                      contactNumber: user['mobile_number'] ?? 'N/A',
                      userId: user['id'] ?? 'N/A',
                      present: user['present'] ?? false,
                      docId: user['id'], // Use user ID to manage Firestore updates
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffc41a00),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              // Save attendance button action
              await addAttendanceWithUsers(context, _selectedDate);
            },
            child: const Text(
              "Save Attendance",
              style: TextStyle(fontSize: 18, fontFamily: 'boldFont'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDateRow() {
    return Container(
      height: 100,
      color: Colors.grey.shade300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left, color: Colors.red),
            iconSize: 50,
            onPressed: _goToPreviousSunday, // Go to previous Sunday
          ),
          Text(
            DateFormat('EEEE, MMM d').format(_selectedDate),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'regularFont',
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_right,
              color:
                  (_selectedDate.add(const Duration(days: 7)).isAfter(_today))
                      ? Colors.grey
                      : Colors.red,
            ),
            iconSize: 50,
            onPressed:
                (_selectedDate.add(const Duration(days: 7)).isAfter(_today))
                    ? null
                    : _goToNextSunday, // Disable on future dates
          ),
        ],
      ),
    );
  }
  
    Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFB32412),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Center(
                child: Text(
                  "Aksar Mandir\nSatsang Pravuti",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group,
                          color: Color(0xFFB32412), size: 29),
                      title: const Text("User", style: TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const UserList()), // Placeholder for UserList screen
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout,
                          color: Color(0xFFB32412), size: 29),
                      title:
                          const Text("Logout", style: TextStyle(fontSize: 18)),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen()), // Placeholder for Login screen
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info,
                          color: Color(0xFFB32412), size: 29),
                      title: const Text("Developed by",
                          style: TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer first
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              title: const Text(
                                "Developed by",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'regularFont',
                                ),
                              ),
                              content: const Text(
                                "Vasu Nageshri and Keval Thumar",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'regularFont',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("Close"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSearchBar() {
    return SizedBox(
      height: 140,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Search by Mobile, Name, ID",
                contentPadding: EdgeInsets.all(8.0),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Search button action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffc41a00),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Clear button action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 25,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Clear",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String name;
  final String contactNumber;
  final String userId;
  final bool present;
  final String docId; // To update the document in Firestore

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.present,
    required this.docId,
  });

  // Toggle present status in Firestore
  Future<void> _togglePresentStatus() async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'present': !present, // Toggle the current value
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        title: Text(
          name,
          style: const TextStyle(fontFamily: 'boldFont'),
        ),
        subtitle: Row(
          children: [Text("$userId - $contactNumber")],
        ),
        trailing: GestureDetector(
          onTap: _togglePresentStatus,
          child: Icon(
            present ? Icons.check_circle : Icons.cancel,
            color: present ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}



// import 'package:aksar_mandir_gondal/Screens/login_screen.dart';
// import 'package:aksar_mandir_gondal/Screens/user_list.dart';
// import 'package:flutter/material.dart';
// // ignore: depend_on_referenced_packages
// import 'package:firebase_auth/firebase_auth.dart';
// // ignore: depend_on_referenced_packages
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<Map<String, String>> users = [];
//   Map<String, bool> attendance =
//       {}; // Map to store user attendance (true: present, false: absent)

//   @override
//   void initState() {
//     super.initState();
//     _fetchUsers();
//   }

//   Future<void> _fetchUsers() async {
//     try {
//       final QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('users').get();
//       setState(() {
//         users = snapshot.docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           // Initialize attendance with false for all users by default
//           attendance[data['id']] =
//               data['present']?.toString() == 'true' ?? false;
//           return {
//             "fullName": data['name']?.toString() ?? 'N/A',
//             "contactNumber": data['mobile_number']?.toString() ?? 'N/A',
//             "userId": data['id']?.toString() ?? 'N/A',
//             "present": data['present']?.toString() ?? 'false',
//           };
//         }).toList();
//       });
//     } catch (e) {
//       print('Error fetching users: $e');
//     }
//   }

//   // Generate PDF function
//   Future<void> _generateAttendancePDF() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text('Attendance Report', style: pw.TextStyle(fontSize: 24)),
//               pw.Text('Date: ${DateTime.now()}'),
//               pw.SizedBox(height: 20),
//               ...attendance.entries.map((entry) {
//                 return pw.Text(
//                     'User ID: ${entry.key}, Present: ${entry.value ? 'Yes' : 'No'}');
//               }).toList(),
//             ],
//           );
//         },
//       ),
//     );

//     // Display PDF preview or save it
//     await Printing.layoutPdf(
//         onLayout: (format) async => pdf.save());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xffc41a00),
//         elevation: 0,
//         title: const Text(
//           "Aksar Mandir Satsang Pravuti",
//           style: TextStyle(
//             fontSize: 22,
//             fontFamily: 'regularFont',
//           ),
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.picture_as_pdf),
//             onPressed: () {
//               _generateAttendancePDF(); // Generate PDF when this icon is pressed
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Your existing UI elements (e.g., Date row, Search bar)

//           const SizedBox(height: 10),

//           // Displaying the user data in a ListView
//           Expanded(
//             child: ListView.builder(
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 final user = users[index];
//                 return ContactCard(
//                   name: user['fullName'] ?? 'N/A',
//                   contactNumber: user['contactNumber'] ?? 'N/A',
//                   userId: user['userId'] ?? 'N/A',
//                   present: attendance[user['userId']] ??
//                       false, // Set present state based on attendance map
//                   onToggle: (newValue) {
//                     setState(() {
//                       attendance[user['userId']!] =
//                           newValue; // Update attendance state
//                     });
//                   },
//                 );
//               },
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Button to manually generate the PDF
//           ElevatedButton(
//             onPressed: _generateAttendancePDF,
//             child: const Text("Generate PDF Report"),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ContactCard extends StatefulWidget {
//   final String name;
//   final String contactNumber;
//   final String userId;
//   final bool present;
//   final Function(bool) onToggle; // Function to notify parent of toggle changes

//   const ContactCard({
//     super.key,
//     required this.name,
//     required this.contactNumber,
//     required this.userId,
//     required this.present,
//     required this.onToggle,
//   });

//   @override
//   ContactCardState createState() => ContactCardState();
// }

// class ContactCardState extends State<ContactCard> {
//   late bool isClicked;

//   @override
//   void initState() {
//     super.initState();
//     isClicked = widget.present; // Initialize with present value
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 5),
//       child: Card(
//         child: ListTile(
//           title: Text(
//             widget.name,
//             style: const TextStyle(fontFamily: 'boldFont'),
//           ),
//           subtitle: Row(
//             children: [Text("${widget.userId} - ${widget.contactNumber}")],
//           ),
//           trailing: IconButton(
//             icon: Icon(
//               isClicked ? Icons.clear : Icons.done,
//               size: 30,
//               color: isClicked ? Colors.red : Colors.green,
//             ),
//             onPressed: () {
//               setState(() {
//                 isClicked = !isClicked;
//                 widget.onToggle(isClicked); // Notify parent of toggle change
//               });
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// /*
// import 'package:aksar_mandir_gondal/Screens/login_screen.dart';
// import 'package:aksar_mandir_gondal/Screens/user_list.dart';
// import 'package:flutter/material.dart';
// // ignore: depend_on_referenced_packages
// import 'package:firebase_auth/firebase_auth.dart';
// // ignore: depend_on_referenced_packages
// import 'package:cloud_firestore/cloud_firestore.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   List<Map<String, String>> users = []; // Initialize an empty list to store users

//   @override
//   void initState() {
//     super.initState();
//     _fetchUsers(); // Fetch users when the screen is initialized
//   }

//   Future<void> _fetchUsers() async {
//     try {
//       final QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('users').get();
//       setState(() {
//         users = snapshot.docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           return {
//             "fullName": data['name']?.toString() ?? 'N/A',  // Convert to String
//             "contactNumber": data['mobile_number']?.toString() ?? 'N/A', // Convert to String
//             "userId": data['id']?.toString() ?? 'N/A', // Convert to String
//             "present": data['present']?.toString() ?? 'false', // Ensure this is a string
//           };
//         }).toList();
//       });
//     } catch (e) {
//       // ignore: avoid_print
//       print('Error fetching users: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xffc41a00),
//         elevation: 0,
//         title: const Text(
//           "Aksar Mandir Satsang Pravuti",
//           style: TextStyle(
//             fontSize: 22,
//             fontFamily: 'regularFont',
//           ),
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//       ),
//       drawer: Drawer(
//         child: Container(
//           color: const Color(0xFFB32412), // Color for the Drawer background
//           child: Column(
//             children: [
//               const DrawerHeader(
//                 decoration: BoxDecoration(
//                   color: Colors.transparent, // Keep it transparent
//                 ),
//                 child: Center(
//                   child: Text(
//                     "Aksar Mandir\nSatsang Pravuti",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Container(
//                   color: Colors.white, // Set the background color to white
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: const Icon(
//                           Icons.group,
//                           color: Color(0xFFB32412), // Change icon color for visibility
//                           size: 29,
//                         ),
//                         title: const Text(
//                           "User",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const UserList(),
//                             ),
//                           );
//                         },
//                       ),
//                       ListTile(
//                         leading: const Icon(
//                           Icons.logout,
//                           color: Color(0xFFB32412), // Change icon color for visibility
//                           size: 29,
//                         ),
//                         title: const Text(
//                           "Logout",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                         onTap: () async {
//                           await FirebaseAuth.instance.signOut(); // Sign out the user
//                           Navigator.pushReplacement(
//                             // ignore: use_build_context_synchronously
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const LoginScreen(),
//                             ),
//                           );
//                         },
//                       ),
//                       ListTile(
//                         leading: const Icon(
//                           Icons.info,
//                           color: Color(0xFFB32412), // Change icon color for visibility
//                           size: 29,
//                         ),
//                         title: const Text(
//                           "Developed by",
//                           style: TextStyle(fontSize: 18),
//                         ),
//                         onTap: () {
//                           Navigator.pop(context); // Close the drawer first
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(20.0),
//                                 ),
//                                 title: const Text(
//                                   "Developed by",
//                                   style: TextStyle(
//                                     fontFamily: 'boldFont',
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold, // Bold for emphasis
//                                   ),
//                                 ),
//                                 content: Padding(
//                                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       RichText(
//                                         text: const TextSpan(
//                                           children: [
//                                             TextSpan(
//                                               text: "This app was developed by\n",
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                             TextSpan(
//                                               text: "Vasu Nageshri and Keval Thumar.",
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         textAlign: TextAlign.center, // Center align the text
//                                       ),
//                                       const SizedBox(height: 10),
//                                       RichText(
//                                         text: const TextSpan(
//                                           children: [
//                                             TextSpan(
//                                               text: "For any inquiries or further development requests,\n",
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                             TextSpan(
//                                               text: "+91 7016457404 & +91 9913201462",
//                                               style: TextStyle(
//                                                 fontSize: 14,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         textAlign: TextAlign.center, // Center align the text
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     child: const Text(
//                                       "Close",
//                                       style: TextStyle(color: Colors.red),
//                                     ),
//                                     onPressed: () {
//                                       Navigator.of(context).pop(); // Close the dialog
//                                     },
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Date Row with Arrows
//           Container(
//             height: 100, // Increase container height
//             color: Colors.grey.shade300,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 // Left Icon (Much larger icon)
//                 Container(
//                   alignment: Alignment.center,
//                   height: 150, // Increase the height to match the icon size
//                   // Set width as needed
//                   child: FittedBox(
//                     child: IconButton(
//                       icon: const Icon(Icons.arrow_left, color: Colors.red),
//                       iconSize: 200, // Increased icon size to 200
//                       onPressed: () {
//                         // Left arrow click action
//                       },
//                     ),
//                   ),
//                 ),
//                 // Date Text
//                 const Text(
//                   "Sun, Sep 29",
//                   style: TextStyle(
//                       fontSize: 20, // Adjust text size as needed
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'regularFont'),
//                 ),
//                 // Right Icon (Much larger icon)
//                 Container(
//                   alignment: Alignment.center,
//                   height: 150, // Increase the height to match the icon size
//                   // Set width as needed
//                   child: FittedBox(
//                     child: IconButton(
//                       icon: const Icon(Icons.arrow_right, color: Colors.black),
//                       iconSize: 200, // Increased icon size to 200
//                       onPressed: () {
//                         // Right arrow click action
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(
//             height: 10,
//           ),
//           // Search Bar
//           SizedBox(
//             height: 140,
//             child: Column(
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.all(15.0),
//                   child: TextField(
//                     decoration: InputDecoration(
//                       border: OutlineInputBorder(),
//                       hintText: "Search by Mobile, Name, ID",
//                       contentPadding: EdgeInsets.all(8.0),
//                     ),
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         // Search button action
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xffc41a00), // Red color
//                         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: const Text(
//                         "Search",
//                         style: TextStyle(fontSize: 18, color: Colors.white),
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Clear button action
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xffc41a00), // Red color
//                         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       child: const Text(
//                         "Clear",
//                         style: TextStyle(fontSize: 18, color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // Displaying the user data in a ListView
//           Expanded(
//             child: ListView.builder(
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 final user = users[index];
//                 return ContactCard(
//                     name: user['fullName'] ?? 'N/A',
//                     contactNumber: user['contactNumber'] ?? 'N/A',
//                     userId: user['userId'] ?? 'N/A',
//                     present: bool.parse(user['present']!) , // Parse string to bool
//                   );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ContactCard extends StatefulWidget {
//   final String name;
//   final String contactNumber;
//   final String userId;
//   final bool present;

//   const ContactCard({
//     super.key,
//     required this.name,
//     required this.contactNumber,
//     required this.userId,
//     required this.present,
//   });

//   @override
//   ContactCardState createState() => ContactCardState();
// }

// */
