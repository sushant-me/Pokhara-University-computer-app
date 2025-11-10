// ignore: unused_import
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:path/path.dart' as p;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PokharaApp());
}

// Helper function for safe, recursive type conversion of Firebase data
Map<String, dynamic> convertFirebaseMap(Map<Object?, Object?> rawMap) {
  final Map<String, dynamic> typedMap = {};
  rawMap.forEach((key, value) {
    if (key is String) {
      if (value is Map<Object?, Object?>) {
        typedMap[key] = convertFirebaseMap(value);
      } else if (value is List<Object?>) {
        typedMap[key] = value.map((e) {
          if (e is Map<Object?, Object?>) {
            return convertFirebaseMap(e);
          }
          return e;
        }).toList();
      } else {
        typedMap[key] = value;
      }
    }
  });
  return typedMap;
}

class PokharaApp extends StatelessWidget {
  const PokharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium UI Theme: Deep Indigo and cool grays for a "Computer Engineering" look
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Pokhara University Syllabus",
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1A237E), // Deep Indigo 900
        scaffoldBackgroundColor:
            const Color(0xFFF5F5F5), // Light Grey background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 8,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          iconColor: Color(0xFF1A237E),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> data = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final snapshot = await ref.child('/').get();

      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value as Map<Object?, Object?>;
        final typedData = convertFirebaseMap(rawData);

        // FIX APPLIED: Drill down one level if the root contains a single, wrapper key (e.g., "Jasonfile")
        if (typedData.length == 1) {
          final singleRootKey = typedData.keys.first;
          final content = typedData[singleRootKey];

          if (content is Map<String, dynamic>) {
            data = content;
          } else {
            // Fallback to the top level map if structure is unexpected
            data = typedData;
          }
        } else {
          data = typedData;
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No data available in Firebase.';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading data from Firebase: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Error: $errorMessage\n\nEnsure Firebase rules allow public read access: ".read": true',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        )),
      );
    }

    List<String> semesters = data.keys.toList();

    // FIX APPLIED: Sort semesters in ascending numerical order
    semesters.sort((a, b) {
      final aNum = int.tryParse(a.split(' ')[0]) ?? 99;
      final bNum = int.tryParse(b.split(' ')[0]) ?? 99;
      return aNum.compareTo(bNum);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            // Logo updated with a circuit board aesthetic for "WOW" factor
            Icon(Icons.developer_board, size: 24, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text("Pokhara University Syllabus"),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: semesters.length,
        itemBuilder: (context, i) {
          final sem = semesters[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Card(
              elevation: 6, // Increased elevation for depth
              // ignore: deprecated_member_use
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      sem.split(' ')[0], // Shows just the number (1, 2, 3...)
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
                title: Text(
                  sem,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF37474F)),
                ),
                trailing: const Icon(Icons.code,
                    size: 20,
                    color: Color(0xFF00BFA5)), // Code icon for tech feel
                onTap: () {
                  // Animated navigation for a premium feel
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SubjectPage(
                              semester: sem,
                              subjects: data[sem] as Map<String, dynamic>),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class SubjectPage extends StatelessWidget {
  final String semester;
  final Map<String, dynamic> subjects;
  const SubjectPage(
      {super.key, required this.semester, required this.subjects});

  @override
  Widget build(BuildContext context) {
    List<String> subjectList = subjects.keys.toList();
    subjectList.sort(); // Sort subjects alphabetically

    return Scaffold(
      appBar: AppBar(title: Text('$semester - Subjects')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: subjectList.length,
        itemBuilder: (context, i) {
          final sub = subjectList[i];
          final categories = subjects[sub] as Map<String, dynamic>;

          List<String> categoryKeys = categories.keys.toList();
          categoryKeys.sort(); // Sort categories (Note, Syllabus)

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 4,
            child: ExpansionTile(
              initiallyExpanded: false,
              backgroundColor: Colors.white,
              collapsedIconColor: Theme.of(context).primaryColor,
              iconColor: const Color(0xFF607D8B),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              title: Text(
                sub,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              children: categoryKeys.map((cat) {
                final files = categories[cat];

                final fileList = (files is Map)
                    ? files.values.toList()
                    : files as List<dynamic>? ?? [];

                if (fileList.isEmpty) {
                  return const SizedBox();
                }

                return Column(
                  children: [
                    Divider(height: 1, color: Colors.grey[200]),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 30, right: 16),
                      leading: Icon(
                        cat.toLowerCase().contains('syllabus')
                            ? Icons.menu_book
                            : Icons.lightbulb_outline,
                        color: Colors
                            .deepOrangeAccent, // Accent color for content type
                      ),
                      title: Text(
                        cat,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        '${fileList.length} files',
                        style: const TextStyle(color: Color(0xFF00BFA5)),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 300),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    FileListPage(
                              category: cat,
                              files: fileList,
                              subject: sub,
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class FileListPage extends StatelessWidget {
  final String category;
  final List<dynamic> files;
  final String subject;
  const FileListPage({
    super.key,
    required this.category,
    required this.files,
    required this.subject,
  });

  IconData _iconFor(String path) {
    final cleanedPath = Uri.decodeComponent(path).toLowerCase();
    if (cleanedPath.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (cleanedPath.contains('doc')) return Icons.description;
    if (cleanedPath.contains('ppt')) return Icons.slideshow;
    if (cleanedPath.contains('jpg') ||
        cleanedPath.contains('jpeg') ||
        cleanedPath.contains('png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  // Helper function to derive a clean file name from the URL
  String _getDisplayName(String path, int index) {
    String fallbackName =
        'Document ${index + 1}'; // Simpler name for cleaner look

    try {
      final uri = Uri.parse(path);

      // Attempt to extract the file name from the path segments if it exists
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.isNotEmpty) {
        String extracted = Uri.decodeComponent(pathSegments.last);

        // If the file was uploaded with a proper name, Google Drive often preserves it
        // before the ID part of the path, or if it's a direct path.
        // We prioritize extracting the last clean segment.
        if (!extracted.contains('view?usp=')) {
          return extracted;
        }
      }

      // Final fallback includes category for context
      return '$category File ${index + 1}';
    } catch (e) {
      return fallbackName;
    }
  }

  // Downloads file from the public URL (Google Drive) and opens it.
  Future<void> _openAsset(String fileUrl, BuildContext context) async {
    // 1. Determine the direct download URL
    final fileIdMatch = RegExp(r'/d/([^/]+)').firstMatch(fileUrl);
    String downloadUrl = fileUrl;

    if (fileIdMatch != null && fileIdMatch.group(1) != null) {
      final fileId = fileIdMatch.group(1);
      // Use the direct download format to ensure the binary content is served.
      downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
      // ignore: avoid_print
      print('Converted to direct download URL: $downloadUrl');
    } else {
      // ignore: avoid_print
      print('Using original URL (conversion failed): $fileUrl');
    }

    // Display download progress feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 10),
            Text(
                'Downloading file: ${_getDisplayName(fileUrl, files.indexOf(fileUrl))}',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        duration: const Duration(minutes: 1), // Keep visible during download
      ),
    );

    try {
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();

        final displayTitle = _getDisplayName(fileUrl, files.indexOf(fileUrl));
        final tempFileName = displayTitle.replaceAll(RegExp(r'[^\w\.\-]'), '_');

        // Determine file extension to ensure OS uses correct viewer
        String extension = '.pdf';
        if (fileUrl.toLowerCase().contains('.doc')) {
          extension = '.doc';
        } else if (fileUrl.toLowerCase().contains('.ppt'))
          // ignore: curly_braces_in_flow_control_structures
          extension = '.ppt';
        else if (fileUrl.toLowerCase().contains('.png') ||
            // ignore: curly_braces_in_flow_control_structures
            fileUrl.toLowerCase().contains('.jpg')) extension = '.png';

        final finalFileName = tempFileName.endsWith(extension)
            ? tempFileName
            : '$tempFileName$extension';

        final tempFile = File('${tempDir.path}/$finalFileName');

        // Write the downloaded bytes (reliable)
        await tempFile.writeAsBytes(response.bodyBytes, flush: true);

        // Use OpenFilex to launch the system's native viewer
        final result = await OpenFilex.open(tempFile.path);

        // Clear the download snackbar and show success
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (result.type != ResultType.done) {
          throw Exception('Failed to open file: ${result.message}');
        }
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('File downloaded and opened successfully!'),
              duration: Duration(seconds: 3)),
        );
      } else {
        // Handle server errors (e.g., Google Drive quota limit, 403, 404)
        throw Exception(
            'Download failed (Status ${response.statusCode}). Check file permissions or link.');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to open or download file: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar(); // Hide existing progress bar
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error downloading file: ${e.toString().split(':').last.trim()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$subject - $category')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: files.length,
        itemBuilder: (context, i) {
          final item = files[i];
          final path = item is String
              ? item
              : (item is List && item.isNotEmpty && item.first is String
                  ? item.first
                  : '');

          if (path.isEmpty) {
            return const SizedBox();
          }

          final displayName = _getDisplayName(path, i);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              elevation: 2,
              child: ListTile(
                tileColor: Colors.white,
                leading:
                    Icon(_iconFor(path), color: Theme.of(context).primaryColor),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing:
                    const Icon(Icons.cloud_download, color: Color(0xFF00BFA5)),
                onTap: () => _openAsset(path, context),
              ),
            ),
          );
        },
      ),
    );
  }
}
