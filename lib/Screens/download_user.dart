import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

Future<void> downloadAttendanceAsPdf(BuildContext context) async {
  try {
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
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: ["Date", "User ID", "Name", "Mobile Number", "Present"],
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

    // Get platform-specific directory to save the PDF file
    Directory? directory;

    if (Platform.isAndroid || Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      directory = await getDownloadsDirectory(); // For desktop platforms
    } else {
      // Web platforms will handle downloads differently, possibly through the printing package
      throw UnsupportedError("Unsupported platform");
    }

    String filePath = "${directory!.path}/attendance_report.pdf";

    // Save the PDF file
    File file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Notify the user that the download is complete
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved at $filePath'),
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
