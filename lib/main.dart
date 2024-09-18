import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart'; // For MediaType

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  List<Map<String, dynamic>> pdfList = [
    {'pdf_url': 'https://example.com/sample1.pdf'},
    {'pdf_url': 'https://example.com/sample2.pdf'},
    {'pdf_url': 'https://example.com/sample3.pdf'},
    {'pdf_url': 'https://example.com/sample4.pdf'},
    {'pdf_url': 'https://example.com/sample5.pdf'},
  ];
  List<Map<String, dynamic>> api2Data = [];

  Future<void> downloadPdf() async {
    const url =
        'https://api.example.com/endpoint1'; // Replace with your API endpoint
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> opList = data['op_list'] as List<dynamic>;
        setState(() {
          pdfList = opList.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        // Handle non-200 status codes
      }
    } catch (e) {
      // Handle errors
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> uploadPdf() async {
    final input = html.FileUploadInputElement();
    input.accept = '.pdf';
    input.multiple = true;

    input.onChange.listen((e) async {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (kDebugMode) {
          print('No files selected');
        }
        return;
      }

      // Prepare the request to the server
      const url =
          'https://api.example.com/upload'; // Replace with your API endpoint

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((e) async {
          final fileBytes = reader.result as Uint8List;

          final request = http.MultipartRequest('POST', Uri.parse(url));

          // Add the file to the request
          final multipartFile = http.MultipartFile.fromBytes(
            'file', // The name of the file parameter expected by your backend
            fileBytes,
            filename: file.name, // Ensure the filename is included
            contentType:
                MediaType('application', 'pdf'), // Set the content type to PDF
          );
          request.files.add(multipartFile);
          try {
            final response = await request.send();
            if (response.statusCode == 200) {
              if (kDebugMode) {
                print('Upload successful for file: ${file.name}');
              }

              // Assuming the backend returns the URL of the uploaded PDF
              final responseBody = await response.stream.bytesToString();
              final pdfUrl =
                  responseBody; // Adjust according to your API's response structure

              // Print the PDF
              await printPdf(pdfUrl);
            } else {
              if (kDebugMode) {
                print(
                    'Upload failed for file: ${file.name} with status code: ${response.statusCode}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Upload failed for file: ${file.name} with error: $e');
            }
          }
        });
      }
    });

    input.click();
  }

  Future<void> printPdf(String pdfUrl) async {
    final Uri uri = Uri.parse(pdfUrl);
    html.window.open(uri.toString(), '_blank');
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF List'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: uploadPdf,
                  child: const Text('ops > upload bill(s)'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: downloadPdf,
                  child: const Text('tenant > view PDF List'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: pdfList.isNotEmpty
                  ? DataTable(
                      columns: const [
                        DataColumn(label: Text('PDF URL')),
                      ],
                      rows: pdfList.map((map) {
                        final url = map['pdf_url']?.toString() ?? '';
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(url),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => _launchURL(url),
                                    tooltip: 'Download PDF',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                  : const Text('No data available'),
            ),
          ],
        ),
      ),
    );
  }
}
