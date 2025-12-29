import 'package:flutter/material.dart';
import 'api_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _isLoading = false;
  bool _isJoiningClass = false;
  bool _isSubmittingAssignment = false;
  List<Map<String, dynamic>> _availableClasses = [];
  final _codeController = TextEditingController();
  final _answerController = TextEditingController();
  final _submitAssignmentFormKey = GlobalKey<FormState>();
  int? _selectedAssignmentId;
  String? _selectedAssignmentTitle;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMaterials(int classId) async {
    print('UI Student: Loading materials for class $classId');
    try {
      final materials = await ApiService.getClassMaterials(classId);
      print('UI Student: Loaded ${materials.length} materials: $materials');
      return materials;
    } catch (e) {
      print('UI Student: Error loading materials: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAssignments(int classId) async {
    print('UI Student: Loading assignments for class $classId');
    try {
      final assignments = await ApiService.getClassAssignments(classId);
      print(
        'UI Student: Loaded ${assignments.length} assignments: $assignments',
      );
      return assignments;
    } catch (e) {
      print('UI Student: Error loading assignments: $e');
      rethrow;
    }
  }

  Future<void> _submitAssignment() async {
    if (!_submitAssignmentFormKey.currentState!.validate()) return;
    if (_selectedAssignmentId == null) return;

    print(
      'UI Student: Starting to submit assignment $_selectedAssignmentId with answer: ${_answerController.text}',
    );

    setState(() {
      _isSubmittingAssignment = true;
    });

    try {
      final response = await ApiService.submitAssignment(
        assignmentId: _selectedAssignmentId!,
        answer: _answerController.text,
      );

      print('UI Student: API call successful, response: $response');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Tugas berhasil dikumpulkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _answerController.clear();
        _selectedAssignmentId = null;
        _selectedAssignmentTitle = null;

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('UI Student: Error in _submitAssignment: $e');
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
          _isSubmittingAssignment = false;
        });
      }
    }
  }

  void _showSubmitAssignmentDialog(int assignmentId, String assignmentTitle) {
    _selectedAssignmentId = assignmentId;
    _selectedAssignmentTitle = assignmentTitle;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kumpulkan Tugas - $assignmentTitle'),
          content: Form(
            key: _submitAssignmentFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _answerController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban Anda',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan jawaban tugas di sini...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jawaban tidak boleh kosong';
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
                _answerController.clear();
                _selectedAssignmentId = null;
                _selectedAssignmentTitle = null;
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isSubmittingAssignment ? null : _submitAssignment,
              child: _isSubmittingAssignment
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kumpulkan'),
            ),
          ],
        );
      },
    );
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
                              maxLines: 3,
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

  Future<void> _joinClass() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode kelas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isJoiningClass = true;
    });

    try {
      final response = await ApiService.joinClass(_codeController.text);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Berhasil bergabung ke kelas!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form and close dialog
        _codeController.clear();
        Navigator.of(context).pop();

        // Reload classes
        await _loadAvailableClasses();
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
          _isJoiningClass = false;
        });
      }
    }
  }

  void _showJoinClassDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bergabung ke Kelas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan kode kelas yang diberikan oleh dosen',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Kelas',
                  hintText: 'Contoh: ABC123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _codeController.clear();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isJoiningClass ? null : _joinClass,
              child: _isJoiningClass
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Bergabung'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAvailableClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes = await ApiService.getMyClasses();
      setState(() {
        _availableClasses = classes;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
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
                  'Kelas Tersedia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bergabunglah dengan kelas yang tersedia',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Action Buttons Row
                Row(
                  children: [
                    // Join Class Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showJoinClassDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Bergabung ke Kelas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Refresh Button
                    ElevatedButton.icon(
                      onPressed: _loadAvailableClasses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Classes List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _availableClasses.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada kelas yang tersedia',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _availableClasses.length,
                          itemBuilder: (context, index) {
                            final classData = _availableClasses[index];
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
                                    if (classData.containsKey('description'))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          classData['description'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Lihat Materi Button
                                    ElevatedButton(
                                      onPressed: () {
                                        _showMaterialsListDialog(
                                          classData['id'],
                                          classData['name'] ?? 'Kelas',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF28a745,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Lihat Materi',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Lihat Tugas Button
                                    ElevatedButton(
                                      onPressed: () {
                                        _showAssignmentsListDialog(
                                          classData['id'],
                                          classData['name'] ?? 'Kelas',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFdc3545,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Lihat Tugas',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Gabung Button (untuk kelas yang belum diikuti)
                                    if (!classData.containsKey('is_joined') ||
                                        classData['is_joined'] == false)
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (classData.containsKey('code')) {
                                            // Pre-fill the code and show join dialog
                                            _codeController.text =
                                                classData['code'];
                                            _showJoinClassDialog();
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Kode kelas tidak tersedia',
                                                ),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF667eea,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Gabung',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      )
                                    else
                                      // Badge untuk kelas yang sudah diikuti
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF28a745),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Bergabung',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
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
                                color: Colors.red,
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
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSubmitAssignmentDialog(
                              assignment['id'],
                              assignment['title'] ?? 'Tugas',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28a745),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Kumpulkan',
                            style: TextStyle(fontSize: 12),
                          ),
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
}
