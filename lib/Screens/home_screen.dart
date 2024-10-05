import 'package:aksar_mandir_gondal/Screens/login_screen.dart';
import 'package:aksar_mandir_gondal/Screens/user_list.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> users = []; // Initialize an empty list to store users

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the screen is initialized
  }

  Future<void> _fetchUsers() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        users = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            "fullName": data['name']?.toString() ?? 'N/A',  // Convert to String
            "contactNumber": data['mobile_number']?.toString() ?? 'N/A', // Convert to String
            "userId": data['id']?.toString() ?? 'N/A', // Convert to String
            "present": data['present']?.toString() ?? 'false', // Ensure this is a string
          };
        }).toList();
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching users: $e');
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
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'regularFont',
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFB32412), // Color for the Drawer background
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.transparent, // Keep it transparent
                ),
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
                  color: Colors.white, // Set the background color to white
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.group,
                          color: Color(0xFFB32412), // Change icon color for visibility
                          size: 29,
                        ),
                        title: const Text(
                          "User",
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserList(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Color(0xFFB32412), // Change icon color for visibility
                          size: 29,
                        ),
                        title: const Text(
                          "Logout",
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut(); // Sign out the user
                          Navigator.pushReplacement(
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.info,
                          color: Color(0xFFB32412), // Change icon color for visibility
                          size: 29,
                        ),
                        title: const Text(
                          "Developed by",
                          style: TextStyle(fontSize: 18),
                        ),
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
                                    fontFamily: 'boldFont',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold, // Bold for emphasis
                                  ),
                                ),
                                content: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "This app was developed by\n",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "Vasu Nageshri and Keval Thumar.",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center, // Center align the text
                                      ),
                                      const SizedBox(height: 10),
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "For any inquiries or further development requests,\n",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "+91 7016457404 & +91 9913201462",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center, // Center align the text
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog
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
      ),
      body: Column(
        children: [
          // Date Row with Arrows
          Container(
            height: 100, // Increase container height
            color: Colors.grey.shade300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Left Icon (Much larger icon)
                Container(
                  alignment: Alignment.center,
                  height: 150, // Increase the height to match the icon size
                  // Set width as needed
                  child: FittedBox(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_left, color: Colors.red),
                      iconSize: 200, // Increased icon size to 200
                      onPressed: () {
                        // Left arrow click action
                      },
                    ),
                  ),
                ),
                // Date Text
                const Text(
                  "Sun, Sep 29",
                  style: TextStyle(
                      fontSize: 20, // Adjust text size as needed
                      fontWeight: FontWeight.bold,
                      fontFamily: 'regularFont'),
                ),
                // Right Icon (Much larger icon)
                Container(
                  alignment: Alignment.center,
                  height: 150, // Increase the height to match the icon size
                  // Set width as needed
                  child: FittedBox(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_right, color: Colors.black),
                      iconSize: 200, // Increased icon size to 200
                      onPressed: () {
                        // Right arrow click action
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),
          // Search Bar
          SizedBox(
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
                        backgroundColor: const Color(0xffc41a00), // Red color
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
                        backgroundColor: const Color(0xffc41a00), // Red color
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
          ),

          const SizedBox(height: 10),

          // Displaying the user data in a ListView
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ContactCard(
                    name: user['fullName'] ?? 'N/A',
                    contactNumber: user['contactNumber'] ?? 'N/A',
                    userId: user['userId'] ?? 'N/A',
                    present: bool.parse(user['present']!) , // Parse string to bool
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class ContactCard extends StatefulWidget {
  final String name;
  final String contactNumber;
  final String userId;
  final bool present;

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.present,
  });

  @override
  ContactCardState createState() => ContactCardState();
}

class ContactCardState extends State<ContactCard> {
  // Boolean to track icon state
  late bool isClicked;

  @override
  void initState() {
    super.initState();
    isClicked = widget.present; // Initialize with present value
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        child: ListTile(
          title: Text(
            widget.name,
            style: const TextStyle(fontFamily: 'boldFont'),
          ),
          subtitle: Row(
            children: [Text("${widget.userId} - ${widget.contactNumber}")],
          ),
          trailing: IconButton(
            icon: Icon(
              isClicked ? Icons.clear : Icons.done, // Change icon based on state
              size: 30,
              color: isClicked ? Colors.red : Colors.green,
            ),
            onPressed: () {
              setState(() {
                isClicked = !isClicked; // Toggle the state
              });
            },
          ),
        ),
      ),
    );
  }
}
