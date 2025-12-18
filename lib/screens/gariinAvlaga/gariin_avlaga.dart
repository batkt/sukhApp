import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class GariinAvlagaPage extends StatelessWidget {
  const GariinAvlagaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(context, title: 'Гарын авлага'),
      body: Container(
        color: context.backgroundColor,
        child: SfPdfViewer.asset(
          'lib/assets/pdf/АмарСӨХ.pdf',
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          enableTextSelection: true,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF ачаалахад алдаа гарлаа: ${details.error}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }
}
