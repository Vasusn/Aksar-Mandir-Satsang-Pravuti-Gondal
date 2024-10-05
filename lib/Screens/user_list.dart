import 'package:aksar_mandir_gondal/Screens/add_user.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserList extends StatelessWidget {
  const UserList({super.key});

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
          Expanded(
            flex: 1,
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
                        backgroundColor: const Color(0xffc41a00),
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
          Expanded(
            flex: 4,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
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

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userData = users[index].data() as Map<String, dynamic>;
                    return ContactCard(
                      name: userData['name'] ?? 'N/A',
                      contactNumber: userData['mobile_number'] ?? 'N/A',
                      userId: userData['id'] ?? 'N/A',
                      documentId: users[index].id, // Pass the document ID
                      onDelete: () => _confirmDelete(context, users[index].id),
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
                await FirebaseFirestore.instance.collection('users').doc(documentId).delete();
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

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.documentId,
    required this.onDelete,
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
                onPressed: () {
                  // Implement edit functionality here
                },
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
