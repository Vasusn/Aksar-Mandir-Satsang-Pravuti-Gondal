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
  List<Map<String, dynamic>> usersData = [];
  List<Map<String, dynamic>> allUsersData = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _today = DateTime.now();
  bool attendanceExists = false; // Track if attendance exists for the selected date

  // Fetch all users and attendance for the selected date
  Future<void> _checkAttendance() async {
    String formattedDate = DateFormat('EEEE, MMM d').format(_selectedDate);
    try {
      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: formattedDate)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        // Attendance found for the selected date
        DocumentSnapshot attendanceDoc = attendanceSnapshot.docs.first;
        setState(() {
          usersData = List<Map<String, dynamic>>.from(attendanceDoc['users']);
          attendanceExists = true;
        });
      } else {
        // No attendance found for the selected date, load all users as absent
        setState(() {
          usersData = [];
          attendanceExists = false;
        });
        await _fetchUsers(); // Fetch users and mark them all absent
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }

  // Fetch all users from the 'users' collection
  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final fetchedUsers = userSnapshot.docs.map((doc) {
        return {
          'id': doc['id'],
          'name': doc['name'],
          'mobile_number': doc['mobile_number'],
          'present': false, // Default to absent (false)
        };
      }).toList();

      setState(() {
        usersData = fetchedUsers;      // Display fetched users
        allUsersData = fetchedUsers;   // Store fetched users for later
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // Toggle present status in the UI for a user
  void _togglePresentStatus(int index) {
    setState(() {
      usersData[index]['present'] = !usersData[index]['present'];
    });
  }

  // Save attendance data for the selected date
  Future<void> _saveAttendance(BuildContext context) async {
    String formattedDate = DateFormat('EEEE, MMM d').format(_selectedDate);
    try {
      QuerySnapshot existingAttendance = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: formattedDate)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance for this date already exists!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Add new attendance data for the selected date
      await FirebaseFirestore.instance.collection('attendance').add({
        'date': formattedDate,
        'users': usersData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving attendance: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _findNextSunday(_selectedDate); // Start with nearest Sunday
    _today = _findNextSunday(_today); // Align today with the nearest Sunday
    _checkAttendance(); // Check attendance when the screen loads
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
      _checkAttendance(); // Check attendance for new selected date
    });
  }

  // Navigate to the next Sunday if it's not a future date
  void _goToNextSunday() {
    if (_selectedDate.add(const Duration(days: 7)).isBefore(_today) ||
        _selectedDate.add(const Duration(days: 7)).isAtSameMomentAs(_today)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        _checkAttendance(); // Check attendance for new selected date
      });
    }
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
            child: usersData.isEmpty
                ? Center(
                    child: attendanceExists
                        ? const CircularProgressIndicator()
                        : const Text(
                            'No attendance found for this date.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                  )
                : ListView.builder(
                    itemCount: usersData.length,
                    itemBuilder: (context, index) {
                      final user = usersData[index];
                      return ContactCard(
                        name: user['name'],
                        contactNumber: user['mobile_number'],
                        userId: user['id'],
                        present: user['present'],
                        onTogglePresent: () => _togglePresentStatus(index),
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
              await _saveAttendance(context); // Save attendance on button press
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (query) {
          setState(() {
            if (query.isEmpty) {
              // If the query is empty, show all users
              usersData = List.from(allUsersData);
            } else {
              // Filter users based on the search query
              usersData = allUsersData.where((user) {
                return user['name'].toLowerCase().contains(query.toLowerCase());
              }).toList();
            }
          });
        },
      ),
    );
  }}


class ContactCard extends StatelessWidget {
  final String name;
  final String contactNumber;
  final String userId;
  final bool present;
  final VoidCallback onTogglePresent;
   // To update the document in Firestore

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.present,
    required this.onTogglePresent,
  });

  // Toggle present status in Firestore
  

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
          onTap: onTogglePresent,
          child: Icon(
            present ? Icons.check_circle : Icons.cancel,
            color: present ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
