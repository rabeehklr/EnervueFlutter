import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportGenerationPage extends StatefulWidget {
  final String? pdfPath;

  const ReportGenerationPage({this.pdfPath});

  @override
  _ReportGenerationPageState createState() => _ReportGenerationPageState();
}

class _ReportGenerationPageState extends State<ReportGenerationPage> {
  List<String> _previousReports = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousReports();
    if (widget.pdfPath != null) {
      _previousReports.insert(0, widget.pdfPath!);
    }
  }

  Future<void> _loadPreviousReports() async {
    final directory = await getTemporaryDirectory();
    final files = directory
        .listSync()
        .where((file) => file.path.endsWith('.pdf'))
        .map((file) => file.path)
        .toList();
    setState(() {
      _previousReports = files;
    });
  }

  Future<void> _deleteReport(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      setState(() {
        _previousReports.remove(filePath);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report deleted successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete report'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadReport(String filePath) async {
    try {
      // Use app-specific directory (no permission needed on Android 13+)
      final documentsDir = await getApplicationDocumentsDirectory();
      final newPath = '${documentsDir.path}/EnerVue_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(filePath).copy(newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to $newPath'), backgroundColor: Colors.green),
      );
      OpenFile.open(newPath);

      // Optional: For Downloads folder via SAF, uncomment and implement below
      // Requires file_picker or SAF integration (additional setup)
      /*
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save EnerVue Report',
        fileName: 'EnerVue_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (result != null) {
        await File(filePath).copy(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to $result'), backgroundColor: Colors.green),
        );
      }
      */
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save report: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareReport(String filePath) async {
    try {
      await Share.shareFiles([filePath], text: 'Check out my EnerVue Cost Estimation Report!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share report'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showDeleteConfirmation(String filePath) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Report'),
          content: Text('Are you sure you want to delete this report?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteReport(filePath);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pdfPath != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('EnerVue Cost Report'),
          actions: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _downloadReport(widget.pdfPath!),
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () => _shareReport(widget.pdfPath!),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(widget.pdfPath!),
            ),
          ],
        ),
        body: PDFView(
          filePath: widget.pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Previous EnerVue Reports')),
      body: _previousReports.isEmpty
          ? Center(child: Text('No reports available', style: TextStyle(fontSize: 16)))
          : ListView.builder(
        itemCount: _previousReports.length,
        itemBuilder: (context, index) {
          final file = File(_previousReports[index]);
          final fileName = file.path.split('/').last;
          return Dismissible(
            key: Key(_previousReports[index]),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Delete Report'),
                    content: Text('Are you sure you want to delete this report?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              _deleteReport(_previousReports[index]);
            },
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Report ${index + 1}'),
              subtitle: Text(fileName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () => _downloadReport(_previousReports[index]),
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => _shareReport(_previousReports[index]),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteConfirmation(_previousReports[index]),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportGenerationPage(pdfPath: _previousReports[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}