import 'package:flutter/material.dart';
import 'api_service.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialFormKey = GlobalKey<FormState>();
  final _assignmentFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialTitleController = TextEditingController();
  final _materialContentController = TextEditingController();
  final _assignmentTitleController = TextEditingController();
  final _assignmentDescriptionController = TextEditingController();
  final _assignmentDeadlineController = TextEditingController();
  bool _isLoading = false;
  bool _isCreatingClass = false;
  bool _isCreatingMaterial = false;
  bool _isCreatingAssignment = false;
  int? _selectedClassId;
  List<Map<String, dynamic>> _myClasses = [];

  @override
  void initState() {
    super.initState();
    _loadMyClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _materialTitleController.dispose();
    _materialContentController.dispose();
    _assignmentTitleController.dispose();
    _assignmentDescriptionController.dispose();
    _assignmentDeadlineController.dispose();
    super.dispose();
  }

  Future<void> _createMaterial() async {
    if (!_materialFormKey.currentState!.validate()) return;
    if (_selectedClassId == null) return;

    print(
      'UI: Starting to create material for class $_selectedClassId with title: ${_materialTitleController.text}',
    );

    setState(() {
      _isCreatingMaterial = true;
    });

    try {
      final response = await ApiService.createMaterial(
        classId: _selectedClassId!,
        title: _materialTitleController.text,
        content: _materialContentController.text,
      );

      print('UI: API call successful, response: $response');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Materi "${response['title']}" berhasil ditambahkan!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _materialTitleController.clear();
        _materialContentController.clear();
        _selectedClassId = null;

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('UI: Error in _createMaterial: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingMaterial = false;
        });
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_assignmentFormKey.currentState!.validate()) return;
    if (_selectedClassId == null) return;

    print(
      'UI: Starting to create assignment for class $_selectedClassId with title: ${_assignmentTitleController.text}',
    );

    setState(() {
      _isCreatingAssignment = true;
    });

    try {
      final response = await ApiService.createAssignment(
        classId: _selectedClassId!,
        title: _assignmentTitleController.text,
        description: _assignmentDescriptionController.text,
        deadline: _assignmentDeadlineController.text,
      );

      print('UI: API call successful, response: $response');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "${response['title']}" berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _assignmentTitleController.clear();
        _assignmentDescriptionController.clear();
        _assignmentDeadlineController.clear();
        _selectedClassId = null;

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('UI: Error in _createAssignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAssignment = false;
        });
      }
    }
  }

  void _showCreateAssignmentDialog(int classId, String className) {
    _selectedClassId = classId;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buat Tugas - $className'),
          content: Form(
            key: _assignmentFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _assignmentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tugas tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignmentDescriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Tugas',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan deskripsi tugas di sini...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tugas tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignmentDeadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    hintText: '2025-01-10',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deadline tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _assignmentTitleController.clear();
                _assignmentDescriptionController.clear();
                _assignmentDeadlineController.clear();
                _selectedClassId = null;
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isCreatingAssignment ? null : _createAssignment,
              child: _isCreatingAssignment
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Tugas'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadMaterials(int classId) async {
    print('UI: Loading materials for class $classId');
    try {
      final materials = await ApiService.getClassMaterials(classId);
      print('UI: Loaded ${materials.length} materials: $materials');
      return materials;
    } catch (e) {
      print('UI: Error loading materials: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAssignments(int classId) async {
    print('UI: Loading assignments for class $classId');
    try {
      final assignments = await ApiService.getClassAssignments(classId);
      print('UI: Loaded ${assignments.length} assignments: $assignments');
      return assignments;
    } catch (e) {
      print('UI: Error loading assignments: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAssignmentSubmissions(
    int assignmentId,
  ) async {
    print('UI: Loading submissions for assignment $assignmentId');
    try {
      final submissions = await ApiService.getAssignmentSubmissions(
        assignmentId,
      );
      print('UI: Loaded ${submissions.length} submissions: $submissions');
      return submissions;
    } catch (e) {
      print('UI: Error loading submissions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadClassInsight(int classId) async {
    print('UI: Loading insights for class $classId');
    try {
      final insight = await ApiService.getClassInsight(classId);
      print('UI: Loaded class insights: $insight');
      return insight;
    } catch (e) {
      print('UI: Error loading insights: $e');
      rethrow;
    }
  }

  void _showMaterialsListDialog(int classId, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Materi Kelas - $className'),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadMaterials(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final materials = snapshot.data ?? [];

              if (materials.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Belum ada materi',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          material['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              material['content'] ?? 'Tanpa Konten',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dibuat: ${material['created_at'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // TODO: Show material options (edit, delete)
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignmentsListDialog(int classId, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tugas Kelas - $className'),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadAssignments(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final assignments = snapshot.data ?? [];

              if (assignments.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Belum ada tugas',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          assignment['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Deadline: ${assignment['deadline'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (assignment.containsKey('description'))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  assignment['description'],
                                  style: const TextStyle(color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Lihat Jawaban Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showSubmissionsListDialog(
                                  assignment['id'],
                                  assignment['title'] ?? 'Tugas',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF17a2b8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Lihat Jawaban',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Menu Button
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 16),
                              onPressed: () {
                                // TODO: Show assignment options (edit, delete)
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showSubmissionsListDialog(int assignmentId, String assignmentTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Jawaban Tugas - $assignmentTitle'),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadAssignmentSubmissions(assignmentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final submissions = snapshot.data ?? [];

              if (submissions.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Belum ada jawaban yang dikumpulkan',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          submission['student'] ?? 'Unknown Student',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Dikumpulkan: ${submission['submitted_at'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jawaban:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: SelectableText(
                                    submission['answer'] ?? 'Tidak ada jawaban',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showClassInsightDialog(int classId, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Insight Kelas - $className'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _loadClassInsight(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final insight = snapshot.data ?? {};

              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Students
                    Card(
                      color: const Color(0xFF007bff),
                      child: ListTile(
                        leading: const Icon(Icons.people, color: Colors.white),
                        title: const Text(
                          'Total Siswa',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '${insight['total_students'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Active Students
                    Card(
                      color: const Color(0xFF28a745),
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Siswa Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '${insight['active_students'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Most Active Material
                    Card(
                      color: const Color(0xFFffc107),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.white),
                        title: const Text(
                          'Materi Paling Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          insight['most_active_material'] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Late Submission
                    Card(
                      color: const Color(0xFFdc3545),
                      child: ListTile(
                        leading: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Submission Terlambat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '${insight['late_submission'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateMaterialDialog(int classId, String className) {
    _selectedClassId = classId;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Materi - $className'),
          content: Form(
            key: _materialFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _materialTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Materi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul materi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _materialContentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Konten Materi',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan konten materi di sini...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konten materi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _materialTitleController.clear();
                _materialContentController.clear();
                _selectedClassId = null;
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isCreatingMaterial ? null : _createMaterial,
              child: _isCreatingMaterial
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tambah Materi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadMyClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes = await ApiService.getMyClasses();
      setState(() {
        _myClasses = classes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingClass = true;
    });

    try {
      final response = await ApiService.createClass(
        name: _nameController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelas "${response['name']}" berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _nameController.clear();
        _descriptionController.clear();

        // Reload classes
        await _loadMyClasses();

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingClass = false;
        });
      }
    }
  }

  void _showCreateClassDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Kelas Baru'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama kelas tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nameController.clear();
                _descriptionController.clear();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isCreatingClass ? null : _createClass,
              child: _isCreatingClass
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Kelas'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.clearTokens();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelas Saya',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Create Class Button
                ElevatedButton.icon(
                  onPressed: _showCreateClassDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Kelas Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667eea),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Classes List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _myClasses.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada kelas yang dibuat',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _myClasses.length,
                          itemBuilder: (context, index) {
                            final classData = _myClasses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  classData['name'] ?? 'Nama Kelas',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      classData['teacher'] ?? 'Dosen',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (classData.containsKey('code'))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Kode: ${classData['code']}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    // Show class options menu
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.people,
                                                ),
                                                title: const Text(
                                                  'Lihat Siswa',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  // TODO: Navigate to students list
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.library_books,
                                                ),
                                                title: const Text(
                                                  'Tambah Materi',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showCreateMaterialDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.list_alt,
                                                ),
                                                title: const Text(
                                                  'Lihat Materi',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showMaterialsListDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.assignment_turned_in,
                                                ),
                                                title: const Text(
                                                  'Lihat Tugas',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showAssignmentsListDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.assignment,
                                                ),
                                                title: const Text('Buat Tugas'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showCreateAssignmentDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.receipt_long,
                                                ),
                                                title: const Text(
                                                  'Lihat Jawaban',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showAssignmentsListDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.insights,
                                                ),
                                                title: const Text(
                                                  'Insight Kelas',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showClassInsightDialog(
                                                    classData['id'],
                                                    classData['name'] ??
                                                        'Kelas',
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.edit),
                                                title: const Text('Edit Kelas'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  // TODO: Show edit class dialog
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
