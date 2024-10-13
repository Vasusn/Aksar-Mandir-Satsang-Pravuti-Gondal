import 'package:aksar_mandir_gondal/Screens/add_user.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  List<Map<String, dynamic>> usersData = []; // List to hold user data
  List<Map<String, dynamic>> allUsersData = []; // List to hold all users data
  final TextEditingController _searchController =
      TextEditingController(); // Controller for search field

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffc41a00),
        elevation: 0,
        title: const Text(
          "User List",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'regularFont',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffc41a00),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddUser(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 80,
            child: _buildSearchBar(),
          ),
          Expanded(
            flex: 9,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching users'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                final users = snapshot.data!.docs;
                allUsersData = users
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList(); // Store all users data
                usersData =
                    _filterUsers(); // Filter users based on search input

                return ListView.builder(
                  itemCount: usersData.isEmpty
                      ? allUsersData.length
                      : usersData.length, // Adjust item count
                  itemBuilder: (context, index) {
                    var userData = usersData.isEmpty
                        ? allUsersData[index]
                        : usersData[index];
                    return ContactCard(
                      name: userData['name'] ?? 'N/A',
                      contactNumber: userData['mobile_number'] ?? 'N/A',
                      userId: userData['id'] ?? 'N/A',
                      documentId: users[index].id, // Pass the document ID
                      onDelete: () => _confirmDelete(context, users[index].id),
                      onEdit: () => _showEditDialog(
                        context,
                        users[index].id, // Pass document ID
                        userData['name'] ?? 'N/A', // Current name
                        userData['mobile_number'] ?? 'N/A', // Current mobile number
                        userData['id'] ?? 'N/A', // Current ID
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: _searchController, // Set the controller
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Search by Name....",
          contentPadding: const EdgeInsets.all(8.0),
        ),
        onChanged: (query) {
          setState(() {
            // Automatically search as user types
            usersData = _filterUsers();
          });
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers() {
    String query = _searchController.text.toLowerCase();
    return allUsersData.where((user) {
      return user['name'].toLowerCase().contains(query) ||
          user['mobile_number']
              .toString()
              .contains(query) || // Assuming mobile number is stored as String
          user['id']
              .toString()
              .contains(query); // Assuming ID is stored as String
    }).toList();
  }

  void _confirmDelete(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(documentId)
                    .delete();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String documentId, String currentName, String currentMobile, String currentId) {
    TextEditingController nameController = TextEditingController(text: currentName);
    TextEditingController mobileController = TextEditingController(text: currentMobile);
    TextEditingController idController = TextEditingController(text: currentId); // For ID field

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: SizedBox(
            height: 200, // Set a fixed height for the dialog
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'User ID'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.green)),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(documentId)
                    .update({
                  'id': idController.text, // Update ID as well
                  'name': nameController.text,
                  'mobile_number': mobileController.text,
                });
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}

class ContactCard extends StatelessWidget {
  final String name;
  final String contactNumber;
  final String userId;
  final String documentId; // Add documentId
  final VoidCallback onDelete; // Callback for delete action
  final VoidCallback onEdit; // Callback for edit action

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.documentId,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Card(
        child: ListTile(
          title: Text(
            name,
            style: const TextStyle(fontFamily: 'boldFont'),
          ),
          subtitle: Row(
            children: [Text("$userId - $contactNumber")],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit, // Call edit action
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete, // Call delete action
              ),
            ],
          ),
        ),
      ),
    );
  }
}
