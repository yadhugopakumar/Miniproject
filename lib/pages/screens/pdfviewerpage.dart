import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewPage extends StatefulWidget {
  final String filePath;
  const PdfViewPage({required this.filePath, super.key});

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late final PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report View', style: TextStyle(fontWeight: FontWeight.w600),),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        
      ),
      body: PdfView(controller: _pdfController, scrollDirection: Axis.vertical),
      backgroundColor: Colors.green[50],
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(
          backgroundColor: Colors.blue[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: () async {
            await Share.shareXFiles(
              [XFile(widget.filePath)],
              text: 'Here is your report',
              subject: 'Medicine Report',
            );
          },
          child: const Icon(Icons.share,color: Colors.black,),
        ),
      ),
    );
  }
}
