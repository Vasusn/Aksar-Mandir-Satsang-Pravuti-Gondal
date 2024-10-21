import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SaveHelper {
  static Future<void> save(List<int> bytes, String fileName) async {
    String? directory = await FilePicker.platform.getDirectoryPath();

    if (directory != null) {
      final File file = File('$directory/$fileName');
      if (file.existsSync()) {
        await file.delete();
      }
      await file.writeAsBytes(bytes);
    }
  }
}

// Function to request storage permission based on Android version
Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted) {
      return true;
    }

    // For Android 11 or higher, we need to request Manage External Storage permission
    if (Platform.isAndroid &&
        (await Permission.manageExternalStorage.isGranted)) {
      return true;
    }

    // Request permission
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // Request Manage External Storage for Android 11 or higher
    if (Platform.isAndroid &&
        (await Permission.manageExternalStorage.request().isGranted)) {
      return true;
    }

    return false; // Permission not granted
  }
  return true; // iOS doesn't require this permission
}

Future<void> downloadAttendanceAsPdf(BuildContext context) async {
  try {
    // Request storage permission for Android
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to save the PDF!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fetch attendance data from Firestore
    QuerySnapshot attendanceSnapshot =
        await FirebaseFirestore.instance.collection('attendance').get();

    if (attendanceSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance data available!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a PDF document
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                "Attendance Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: [
                  "Date",
                  "User ID",
                  "Name",
                  "Mobile Number",
                  "Present"
                ],
                data: attendanceSnapshot.docs.expand((attendanceDoc) {
                  String date = attendanceDoc['date'];
                  List<dynamic> users = attendanceDoc['users'];
                  return users.map((user) {
                    return [
                      date,
                      user['id'],
                      user['name'],
                      user['mobile_number'],
                      user['present'] ? 'Present' : 'Absent',
                    ];
                  }).toList();
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF using SaveHelper
    List<int> pdfBytes = await pdf.save();
    await SaveHelper.save(pdfBytes, "attendance_report.pdf");

    // Notify the user that the download is complete
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('Error creating PDF file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to download the attendance PDF!'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
