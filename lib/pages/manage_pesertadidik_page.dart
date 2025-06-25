import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pesertadidik.dart';
import '../models/orangtua.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class ManagePesertaDidikPage extends StatefulWidget {
  const ManagePesertaDidikPage({Key? key}) : super(key: key);

  @override
  State<ManagePesertaDidikPage> createState() => _ManagePesertaDidikPageState();
}

class _ManagePesertaDidikPageState extends State<ManagePesertaDidikPage> {
  final ApiService apiService = ApiService();
  late Future<List<PesertaDidik>> pesertaDidikFuture;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    pesertaDidikFuture = apiService.getPesertaDidikList();
  }

  void _refresh() {
    setState(() {
      pesertaDidikFuture = apiService.getPesertaDidikList();
    });
  }

  void _showForm({PesertaDidik? peserta, bool isEdit = false}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PesertaDidikFormPage(peserta: peserta, isEdit: isEdit),
      ),
    );
    if (result != null) {
      try {
        if (isEdit && peserta != null) {
          await apiService.updatePesertaDidik(
            peserta.nis,
            result['data'],
            foto: result['foto'],
            filePenilaian: result['filePenilaian'],
          );
        } else {
          await apiService.createPesertaDidik(
            result['data'],
            foto: result['foto'],
            filePenilaian: result['filePenilaian'],
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Data berhasil diupdate' : 'Data berhasil ditambah'), backgroundColor: Colors.green),
        );
        _refresh();
      } catch (e) {
        print('Error saving PesertaDidik: $e'); // Added for more detailed debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deletePeserta(String nis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Peserta Didik'),
        content: Text('Yakin ingin menghapus peserta didik ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await apiService.deletePesertaDidik(nis);
        await Future.delayed(Duration(milliseconds: 100));
        _refresh();
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data berhasil dihapus'), backgroundColor: Colors.green),
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _uploadPenilaian(PesertaDidik peserta) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      try {
        await apiService.uploadPenilaian(peserta.nis, File(picked.path));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File penilaian berhasil diupload'), backgroundColor: Colors.green),
        );
        _refresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kelola Peserta Didik')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: Icon(Icons.add),
        tooltip: 'Tambah Peserta Didik',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari nama peserta didik',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PesertaDidik>>(
              future: pesertaDidikFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Belum ada data peserta didik.'));
                }
                final list = snapshot.data!;
                final filteredList = searchQuery.isEmpty
                    ? list
                    : list.where((pd) => pd.namaPd.toLowerCase().contains(searchQuery)).toList();
                if (filteredList.isEmpty) {
                  return Center(child: Text('Tidak ditemukan peserta didik dengan nama tersebut.'));
                }
                return ListView.separated(
                  padding: EdgeInsets.all(8),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final pd = filteredList[i];
                    String? fotoUrl = pd.foto;
                    if (fotoUrl != null && fotoUrl.isNotEmpty && !fotoUrl.startsWith('http')) {
                      fotoUrl = 'https://projek1-production.up.railway.app/storage/' + fotoUrl.replaceFirst(RegExp(r'^/?'), '');
                    }
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                              ? NetworkImage(fotoUrl)
                              : null,
                          onBackgroundImageError: (_, __) {},
                          child: (fotoUrl == null || fotoUrl.isEmpty)
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(pd.namaPd, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIS: ${pd.nis}', style: TextStyle(fontSize: 13)),
                            Text('Kelas: ${pd.kelas} | Fase: ${pd.fase}', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showForm(peserta: pd, isEdit: true),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePeserta(pd.nis),
                              tooltip: 'Hapus',
                            ),
                            IconButton(
                              icon: Icon(Icons.upload_file, color: Colors.orange),
                              onPressed: () => _uploadPenilaian(pd),
                              tooltip: 'Upload Penilaian',
                            ),
                            if (pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.download, color: Colors.green),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('File Penilaian'),
                                      content: Text('Link: ${pd.filePenilaian}'),
                                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Tutup'))],
                                    ),
                                  );
                                },
                                tooltip: 'Lihat/Download Penilaian',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PesertaDidikFormPage extends StatefulWidget {
  final PesertaDidik? peserta;
  final bool isEdit;
  const PesertaDidikFormPage({this.peserta, this.isEdit = false, Key? key}) : super(key: key);

  @override
  State<PesertaDidikFormPage> createState() => _PesertaDidikFormPageState();
}

class _PesertaDidikFormPageState extends State<PesertaDidikFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaCtrl = TextEditingController();
  final TextEditingController tglLahirCtrl = TextEditingController();
  String? selectedKelas;
  final TextEditingController tinggiCtrl = TextEditingController();
  final TextEditingController beratCtrl = TextEditingController();
  String jenisKelamin = 'Laki-laki';
  File? foto;
  String? existingFotoUrl;
  bool hasExistingPhoto = false;
  File? filePenilaian;
  String? filePenilaianName;
  int? fotoSize;
  List<Orangtua> orangtuaList = [];
  Orangtua? selectedOrangtua;
  bool orangtuaLoading = false;
  DateTime? selectedDate;
  final List<String> kelasOptions = [
    'A', 'B'
  ];
  String? kelas;

  @override
  void initState() {
    super.initState();
    if (widget.peserta != null) {
      namaCtrl.text = widget.peserta!.namaPd;
      tglLahirCtrl.text = widget.peserta!.tanggalLahir;
      kelas = widget.peserta!.kelas;
      selectedKelas = widget.peserta!.kelas;
      tinggiCtrl.text = widget.peserta!.tinggiBadan.toString();
      beratCtrl.text = widget.peserta!.beratBadan.toString();
      jenisKelamin = widget.peserta!.jenisKelamin;
      if (widget.peserta!.tanggalLahir.isNotEmpty) {
        selectedDate = DateTime.tryParse(widget.peserta!.tanggalLahir);
      }
      
      // Initialize existing photo URL
      if (widget.peserta!.foto != null && widget.peserta!.foto!.isNotEmpty) {
        String fotoUrl = widget.peserta!.foto!;
        if (!fotoUrl.startsWith('http')) {
          fotoUrl = 'https://projek1-production.up.railway.app/storage/' + fotoUrl.replaceFirst(RegExp(r'^/?'), '');
        }
        setState(() {
          existingFotoUrl = fotoUrl;
          hasExistingPhoto = true;
        });
      }
    }
    _loadOrangtua();
  }

  Future<void> _loadOrangtua() async {
    setState(() { orangtuaLoading = true; });
    try {
      final list = await ApiService().getOrangtuaList();
      setState(() {
        orangtuaList = list;
        if (widget.peserta != null) {
          try {
            selectedOrangtua = list.firstWhere((o) => o.id == widget.peserta!.idOrtu);
          } catch (_) {
            selectedOrangtua = list.isNotEmpty ? list.first : null;
          }
        }
      });
    } catch (e) {
      // ignore error, just show empty
    } finally {
      setState(() { orangtuaLoading = false; });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 5),
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('id'),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        tglLahirCtrl.text = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }                  Future<void> _pickFoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Ambil dari Kamera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 600);
                if (picked != null) {
                  File file = File(picked.path);
                  int size = await file.length();
                  setState(() {
                    foto = file;
                    fotoSize = size;
                    // Mark that we have a new photo, old photo will be replaced if there was one
                    if (widget.isEdit) {
                      hasExistingPhoto = false;
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                if (result != null && result.files.single.path != null) {
                  File file = File(result.files.single.path!);
                  int size = await file.length();
                  // Kompres jika > 1MB
                  if (size > 1024 * 1024) {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 600);
                    if (picked != null) {
                      file = File(picked.path);
                      size = await file.length();
                    }
                  }
                  setState(() {
                    foto = file;
                    fotoSize = size;
                    // Mark that we have a new photo, old photo will be replaced if there was one
                    if (widget.isEdit) {
                      hasExistingPhoto = false;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPenilaian() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        filePenilaian = File(result.files.single.path!);
        filePenilaianName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Peserta Didik' : 'Tambah Peserta Didik'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: tglLahirCtrl,
                    decoration: InputDecoration(labelText: 'Tanggal Lahir'),
                    validator: (v) => v == null || v.isEmpty ? 'Tanggal lahir wajib diisi' : null,
                  ),
                ),
              ),
              Row(
                children: [
                  Text('Jenis Kelamin:'),
                  Radio<String>(
                    value: 'Laki-laki',
                    groupValue: jenisKelamin,
                    onChanged: (v) => setState(() => jenisKelamin = v!),
                  ),
                  Text('Laki-laki'),
                  Radio<String>(
                    value: 'Perempuan',
                    groupValue: jenisKelamin,
                    onChanged: (v) => setState(() => jenisKelamin = v!),
                  ),
                  Text('Perempuan'),
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedKelas,
                decoration: InputDecoration(labelText: 'Kelas'),
                items: kelasOptions.map((k) => DropdownMenuItem(
                  value: k,
                  child: Text(k),
                )).toList(),
                onChanged: (v) => setState(() {
                  selectedKelas = v;
                  kelas = v ?? '';
                }),
                validator: (v) => v == null || v.isEmpty ? 'Kelas wajib diisi' : null,
              ),
              TextFormField(
                controller: tinggiCtrl,
                decoration: InputDecoration(labelText: 'Tinggi Badan'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: beratCtrl,
                decoration: InputDecoration(labelText: 'Berat Badan'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Text('Orangtua:'),
              orangtuaLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  : DropdownButtonFormField<Orangtua>(
                      value: selectedOrangtua,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'Orangtua'),
                      items: orangtuaList.map((o) {
                        return DropdownMenuItem<Orangtua>(
                          value: o,
                          child: Text(o.namaOrtu),
                        );
                      }).toList(),
                      onChanged: (o) => setState(() => selectedOrangtua = o),
                      validator: (v) => v == null ? 'Pilih orangtua' : null,
                    ),
              SizedBox(height: 16),
              Text('Foto Siswa:'),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFoto,
                    icon: Icon(Icons.image),
                    label: Text('Pilih/Ambil Foto'),
                  ),
                  if (foto != null) ...[
                    SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        foto!, 
                        width: 48, 
                        height: 48, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, size: 24),
                          ),
                      ),
                    ),
                    if (fotoSize != null)
                      Text(' ${(fotoSize! / 1024).toStringAsFixed(0)} KB', style: TextStyle(fontSize: 12)),
                  ],
                  if (hasExistingPhoto && existingFotoUrl != null) ...[
                    SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        existingFotoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, size: 24),
                          ),
                      ),
                    ),
                    Text(' Foto Lama', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              SizedBox(height: 8),
              Text('File Penilaian (PDF/DOC/DOCX, opsional):'),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickPenilaian,
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Penilaian'),
                  ),
                  if (filePenilaian != null) ...[
                    SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.green),
                    if (filePenilaianName != null)
                      Text(' $filePenilaianName', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'data': {
                            'namapd': namaCtrl.text,
                            'tanggallahir': tglLahirCtrl.text,
                            'jeniskelamin': jenisKelamin,
                            'kelas': selectedKelas ?? '',
                            'tinggibadan': int.tryParse(tinggiCtrl.text) ?? 0,
                            'beratbadan': int.tryParse(beratCtrl.text) ?? 0,
                            'idortu': selectedOrangtua?.id,
                          },
                          'foto': foto,
                          'filePenilaian': filePenilaian,
                        });
                      }
                    },
                    child: Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}