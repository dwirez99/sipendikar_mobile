import 'package:flutter/material.dart';
import '../models/orangtua.dart';
import '../services/api_service.dart';

class ManageOrangtuaPage extends StatefulWidget {
  const ManageOrangtuaPage({super.key});

  @override
  State<ManageOrangtuaPage> createState() => _ManageOrangtuaPageState();
}

class _ManageOrangtuaPageState extends State<ManageOrangtuaPage> {
  final ApiService apiService = ApiService();
  late Future<List<Orangtua>> futureOrangtua;

  @override
  void initState() {
    super.initState();
    _loadOrangtua();
  }

  void _loadOrangtua() {
    setState(() {
      futureOrangtua = apiService.getOrangtuaList();
    });
  }

  void _showForm({Orangtua? orangtua}) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => OrangtuaFormDialog(
        orangtua: orangtua,
        onSubmit: (data) async {
          try {
            // Get user data to set nickname as username
            Map<String, dynamic> submitData = data;
            if (orangtua == null) {
              // Only add nickname for new orangtua - email and nickname will be auto-generated in database
              final userData = await apiService.getUser();
              print('User data: $userData'); // Debug log
              if (userData != null && userData['username'] != null) {
                submitData['nickname'] = userData['username'];
              } else {
                // Fallback: use name as nickname if username not available
                submitData['nickname'] = data['namaortu'] ?? 'orangtua';
              }
              print('Submit data: $submitData'); // Debug log
              await apiService.createOrangtua(submitData);
              Navigator.pop(context, {'success': true, 'action': 'create'});
            } else {
              await apiService.updateOrangtua(orangtua.id, submitData);
              Navigator.pop(context, {'success': true, 'action': 'update'});
            }
          } catch (e) {
            Navigator.pop(context, {'success': false, 'error': e.toString()});
          }
        },
      ),
    );
    
    // Handle result and show appropriate snackbar
    if (result != null) {
      if (result['success'] == true) {
        String action = result['action'];
        String message = action == 'create' 
          ? 'Data orangtua berhasil ditambahkan!' 
          : 'Data orangtua berhasil diperbarui!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        _loadOrangtua();
      } else {
        // Show error message
        String error = result['error'] ?? 'Terjadi kesalahan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data orangtua: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteOrangtua(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await apiService.deleteOrangtua(id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data orangtua berhasil dihapus!'), backgroundColor: Colors.green),
      );
      _loadOrangtua();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus orangtua: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Orangtua'),
        backgroundColor: const Color(0xFF00B7FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrangtua,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Orangtua'),
        backgroundColor: const Color(0xFF00B7FF),
      ),
      body: FutureBuilder<List<Orangtua>>(
        future: futureOrangtua,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data orangtua.'));
          } else {
            final orangtuas = snapshot.data!;
            return ListView.builder(
              itemCount: orangtuas.length,
              itemBuilder: (context, index) {                  final orangtua = orangtuas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(orangtua.namaOrtu),
                    subtitle: Text('No. Telp: ${orangtua.notelpOrtu}\nAlamat: ${orangtua.alamat}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showForm(orangtua: orangtua),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: const Text('Hapus data orangtua ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteOrangtua(orangtua.id);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class OrangtuaFormDialog extends StatefulWidget {
  final Orangtua? orangtua;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  const OrangtuaFormDialog({super.key, this.orangtua, required this.onSubmit});

  @override
  State<OrangtuaFormDialog> createState() => _OrangtuaFormDialogState();
}

class _OrangtuaFormDialogState extends State<OrangtuaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _notelpController;
  late TextEditingController _alamatController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.orangtua?.namaOrtu ?? '');
    _notelpController = TextEditingController(text: widget.orangtua?.notelpOrtu ?? '');
    _alamatController = TextEditingController(text: widget.orangtua?.alamat ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _notelpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await widget.onSubmit({
          'namaortu': _namaController.text,
          'notelportu': _notelpController.text,
          'alamat': _alamatController.text,
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.orangtua == null ? 'Tambah Orangtua' : 'Edit Orangtua'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Orangtua'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _notelpController,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Simpan'),
        ),
      ],
    );
  }
}
