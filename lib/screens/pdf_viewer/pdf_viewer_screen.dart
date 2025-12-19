import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class PdfViewerScreen extends StatelessWidget {
  final String? pdfPath;
  final String? pdfAsset;

  const PdfViewerScreen({
    super.key,
    this.pdfPath,
    this.pdfAsset,
  }) : assert(pdfPath != null || pdfAsset != null,
            'Either pdfPath or pdfAsset must be provided');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Гарын авлага',
      ),
      body: Container(
        color: context.backgroundColor,
        child: SfPdfViewer.asset(
          pdfAsset ?? pdfPath!,
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

