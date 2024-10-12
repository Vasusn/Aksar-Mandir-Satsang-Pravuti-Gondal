import 'package:aksar_mandir_gondal/Screens/add_user.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<DocumentSnapshot> _filteredUsers = [];
  List<DocumentSnapshot> _users = [];
  bool _isSearching = false;

  // Perform the search when the search button is pressed
  void _performSearch(String query, List<DocumentSnapshot> users) {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
      _filteredUsers = users.where((user) {
        var userData = user.data() as Map<String, dynamic>;
        return (userData['name']?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (userData['id']?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (userData['mobile_number']
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false);
      }).toList();

      // Show a snackbar if no users found
      if (_filteredUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No users found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
    });
  }

  // Clear the search and reset the user list
  void _clearSearch() {
    setState(() {
      _searchQuery = "";
      _isSearching = false;
      _searchController.clear();
    });
  }

  int userLength = 0;
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
              builder: (context) => AddUser(
                userId: userLength,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextFormField(
                  controller: _searchController,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name *',
                    hintText: 'Search by Name',
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
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Get the search query and perform the search
                      String query = _searchController.text.trim();
                      if (query.isNotEmpty) {
                        // Perform search using the full users list
                        _performSearch(query, _users);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffc41a00),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
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
                    onPressed: _clearSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
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
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('id')
                  .snapshots(),
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
                userLength = users.length;

                // If searching, use the filtered users, otherwise use the full list
                _users = users;
                List<DocumentSnapshot> displayUsers =
                    _isSearching ? _filteredUsers : users;

                return ListView.builder(
                  itemCount: displayUsers.length,
                  itemBuilder: (context, index) {
                    var userData =
                        displayUsers[index].data() as Map<String, dynamic>;
                    return ContactCard(
                      name: userData['name'] ?? 'N/A',
                      contactNumber: userData['mobile_number'] ?? 'N/A',
                      userId: userData['id'] ?? 'N/A',
                      documentId:
                          displayUsers[index].id, // Pass the document ID
                      onDelete: () =>
                          _confirmDelete(context, displayUsers[index].id),
                      userData: userData,
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(documentId)
                    .delete();
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
  final String documentId;
  final VoidCallback onDelete;
  final Map<String, dynamic>? userData;

  const ContactCard({
    super.key,
    required this.name,
    required this.contactNumber,
    required this.userId,
    required this.documentId,
    required this.onDelete,
    this.userData,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddUser(
                        userId: int.parse(userId),
                        isEditing: true,
                        userData: userData, // Pass existing user data
                      ),
                    ),
                  );
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
