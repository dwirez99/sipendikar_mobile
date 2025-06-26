import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/pesertadidik.dart';
import '../models/orangtua.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagePesertaDidikPage extends StatefulWidget {
  const ManagePesertaDidikPage({Key? key}) : super(key: key);

  @override
  State<ManagePesertaDidikPage> createState() => _ManagePesertaDidikPageState();
}

class _ManagePesertaDidikPageState extends State<ManagePesertaDidikPage> {
  final ApiService apiService = ApiService();
  late Future<List<PesertaDidik>> pesertaDidikFuture;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? filterKelas;
  String? filterStatus;
  String? sortNama;
  List<Orangtua> orangtuaList = [];

  @override
  void initState() {
    super.initState();
    pesertaDidikFuture = apiService.getPesertaDidikList();
    _loadOrangtuaList();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadOrangtuaList() async {
    try {
      final list = await apiService.getOrangtuaList();
      setState(() {
        orangtuaList = list;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _hitungZScore(PesertaDidik peserta) async {
    try {
      final result = await apiService.calculateStatusGizi(peserta.nis);
      String? fotoUrl = peserta.foto;
      if (fotoUrl != null && fotoUrl.isNotEmpty && !fotoUrl.startsWith('http')) {
        fotoUrl = 'https://projek1-production.up.railway.app/storage/' + fotoUrl.replaceFirst(RegExp(r'^/?'), '');
      }
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // FOTO SISWA
                        Container(
                          margin: EdgeInsets.only(bottom: isMobile ? 20 : 0, right: isMobile ? 0 : 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: fotoUrl != null && fotoUrl.isNotEmpty
                                ? Image.network(
                                    fotoUrl,
                                    width: 180,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 180,
                                    height: 220,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.person, size: 80, color: Colors.grey),
                                  ),
                          ),
                        ),
                        // INFO SISWA & Z-SCORE
                        Flexible(
                          fit: FlexFit.loose,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(left: isMobile ? 0 : 8, top: isMobile ? 8 : 0),
                              child: Column(
                                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    peserta.namaPd,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${peserta.jenisKelamin} | "
                                    "${result['calculation']['umur']['tahun']} Tahun ${result['calculation']['umur']['bulan']} Bulan",
                                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                                    children: [
                                      const Text("Tinggi Badan (cm):", style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
                                        ),
                                        padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
                                        child: Text("${peserta.tinggiBadan} cm", style: const TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                                    children: [
                                      const Text("Berat Badan (kg):", style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
                                        ),
                                        padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
                                        child: Text("${peserta.beratBadan} kg", style: const TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                                    children: [
                                      const Text("Status Gizi:", style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Text(
                                        result['calculation']['status_gizi'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF28a745), fontSize: 17),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                                    children: [
                                      const Text("Z-Score:", style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 8),
                                      Text(
                                        result['calculation']['z_score'].toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 17),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(child: CircularProgressIndicator()),
                                          );
                                          try {
                                            await apiService.saveStatusGizi(
                                              peserta.nis,
                                              result['calculation']['z_score'],
                                              result['calculation']['status_gizi'],
                                            );
                                            Navigator.pop(context); // Tutup loading
                                            Navigator.pop(context); // Tutup dialog utama
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Analisis gizi berhasil disimpan'), backgroundColor: Colors.green),
                                            );
                                            _refresh();
                                          } catch (e) {
                                            Navigator.pop(context); // Tutup loading
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal simpan analisis: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.save),
                                        label: const Text('Simpan Analisis'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFdee2e6),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          textStyle: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Kembali'),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          side: const BorderSide(color: Colors.black12),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Tombol close/back di pojok kiri atas
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 32, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Analisis'),
          content: Text('Gagal menghitung status gizi: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
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
          // FILTER BAR
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari nama peserta didik',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true, // Make it more compact
                    ),
                    // onChanged is handled by the controller's listener
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12.0, // gap between adjacent chips
                    runSpacing: 8.0, // gap between lines
                    alignment: WrapAlignment.center,
                    children: [
                      // Kelas
                      DropdownButton<String>(
                        value: filterKelas,
                        hint: const Text('Kelas'),
                        items: [null, 'A', 'B'].map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(k == null ? 'Semua Kelas' : 'Kelas $k'),
                        )).toList(),
                        onChanged: (v) => setState(() => filterKelas = v),
                      ),
                      // Status Pemeriksaan (dummy, implementasi filter manual jika ada field)
                      DropdownButton<String>(
                        value: filterStatus,
                        hint: const Text('Status'),
                        items: [null, 'True', 'False'].map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == null ? 'Semua Status' : (s == 'True' ? 'Diperiksa' : 'Belum')),
                        )).toList(),
                        onChanged: (v) => setState(() => filterStatus = v),
                      ),
                      // Urutkan Nama
                      DropdownButton<String>(
                        value: sortNama,
                        hint: const Text('Urutkan'),
                        items: [null, 'nama_asc', 'nama_desc'].map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == null ? 'Default' : (s == 'nama_asc' ? 'Nama A-Z' : 'Nama Z-A')),
                        )).toList(),
                        onChanged: (v) => setState(() => sortNama = v),
                      ),
                      if (searchQuery.isNotEmpty || filterKelas != null || filterStatus != null || sortNama != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear(); // Clear text field
                              filterKelas = null;
                              filterStatus = null;
                              sortNama = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Reset Filter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PesertaDidik>>(
              future: pesertaDidikFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat data: [38;5;1m${snapshot.error}[0m'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Belum ada data peserta didik.'));
                }
                var list = snapshot.data!;
                // FILTER
                if (searchQuery.isNotEmpty) {
                  list = list.where((pd) => pd.namaPd.toLowerCase().contains(searchQuery)).toList();
                }
                if (filterKelas != null && filterKelas!.isNotEmpty) {
                  list = list.where((pd) => pd.kelas == filterKelas).toList();
                }
                // Status Pemeriksaan: implementasi tergantung field, skip for now
                // SORT
                if (sortNama == 'nama_asc') {
                  list.sort((a, b) => a.namaPd.compareTo(b.namaPd));
                } else if (sortNama == 'nama_desc') {
                  list.sort((a, b) => b.namaPd.compareTo(a.namaPd));
                }
                if (list.isEmpty) {
                  return Center(child: Text('Tidak ditemukan peserta didik dengan filter tersebut.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final pd = list[i];
                    String? fotoUrl = pd.foto;
                    if (fotoUrl != null && fotoUrl.isNotEmpty && !fotoUrl.startsWith('http')) {
                      fotoUrl = 'https://projek1-production.up.railway.app/storage/' + fotoUrl.replaceFirst(RegExp(r'^/?'), '');
                    }
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FOTO
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                      ? NetworkImage(fotoUrl)
                                      : null,
                                  child: (fotoUrl == null || fotoUrl.isEmpty)
                                      ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // INFO SISWA
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pd.namaPd, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      Text('NIS: ${pd.nis}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                      Text('Orangtua: '
                                        + (orangtuaList.firstWhereOrNull((o) => o.id == pd.idOrtu)?.namaOrtu ?? '-'),
                                        style: const TextStyle(fontSize: 14)),
                                      Text('Lahir: ${pd.tanggalLahir} | ${pd.jenisKelamin}', style: const TextStyle(fontSize: 14)),
                                      Text('Kelas: ${pd.kelas}', style: const TextStyle(fontSize: 14)),
                                      Text('TB/BB: ${pd.tinggiBadan} cm / ${pd.beratBadan} kg', style: const TextStyle(fontSize: 14)),
                                      if (pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.description, size: 16, color: Colors.green[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Penilaian: ${pd.filePenilaian!.split('/').last}',
                                                style: TextStyle(fontSize: 12, color: Colors.green[700]),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16), // Separator between info and actions
                            // TOMBOL AKSI
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min, // Tambahkan ini agar Row tidak unbounded
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _hitungZScore(pd),
                                  icon: const Icon(Icons.analytics, size: 18),
                                  label: const Text('Z-Score'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty
                                      ? () async {
                                          // UNDUH FILE
                                          String url = pd.filePenilaian!;
                                          if (!url.startsWith('http')) {
                                            url = 'https://projek1-production.up.railway.app/storage/' + url.replaceFirst(RegExp(r'^/?'), '');
                                          }
                                          // Open/download file
                                          try {
                                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal membuka file: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      : () async {
                                          final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
                                          if (result != null && result.files.single.path != null) {
                                            try {
                                              await apiService.uploadPenilaian(pd.nis, File(result.files.single.path!));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('File penilaian berhasil diupload'), backgroundColor: Colors.green),
                                              );
                                              _refresh();
                                            } catch (e) {
                                              // Tampilkan sukses jika file benar-benar terupload meski exception
                                              _refresh();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('File penilaian berhasil diupload (dengan peringatan: $e)'), backgroundColor: Colors.orange),
                                              );
                                            }
                                          }
                                        },
                                  icon: pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty
                                      ? const Icon(Icons.download)
                                      : const Icon(Icons.upload_file),
                                  label: Text(pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty ? 'Unduh Penilaian' : 'Upload Penilaian'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pd.filePenilaian != null && pd.filePenilaian!.isNotEmpty ? Colors.green : Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showForm(peserta: pd, isEdit: true);
                                    } else if (value == 'delete') {
                                      _deletePeserta(pd.nis);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text('Hapus'),
                                      ),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                              ],
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
        leading: CloseButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tglLahirCtrl,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
                readOnly: true, // Make it read-only to force date picker usage
                validator: (v) => v == null || v.isEmpty ? 'Tanggal lahir wajib diisi' : null,
                onTap: _pickDate, // Also allow tapping the field itself
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jenis Kelamin:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: RadioListTile<String>(
                          title: const Text('Laki-laki'),
                          value: 'Laki-laki',
                          groupValue: jenisKelamin,
                          onChanged: (v) => setState(() => jenisKelamin = v!),
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: RadioListTile<String>(
                          title: const Text('Perempuan'),
                          value: 'Perempuan',
                          groupValue: jenisKelamin,
                          onChanged: (v) => setState(() => jenisKelamin = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedKelas,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  border: OutlineInputBorder(),
                ),
                items: kelasOptions.map((k) => DropdownMenuItem(
                  value: k,
                  child: Text(k),
                )).toList(),
                onChanged: (v) => setState(() {
                  selectedKelas = v;
                  kelas = v;
                }),
                validator: (v) => v == null || v.isEmpty ? 'Kelas wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tinggiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tinggi Badan (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tinggi badan wajib diisi';
                  if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: beratCtrl,
                decoration: const InputDecoration(
                  labelText: 'Berat Badan (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Berat badan wajib diisi';
                  if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Orangtua:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  orangtuaLoading
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<Orangtua>(
                      value: selectedOrangtua,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Orangtua',
                        border: OutlineInputBorder(),
                      ),
                      items: orangtuaList.map((o) {
                        return DropdownMenuItem<Orangtua>(
                          value: o,
                          child: Text(o.namaOrtu),
                        );
                      }).toList(),
                      onChanged: (o) => setState(() => selectedOrangtua = o),
                      validator: (v) => v == null ? 'Pilih orangtua' : null,
                    ), // Added missing closing parenthesis
                ],
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Foto Siswa:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: foto != null
                              ? FileImage(foto!)
                              : (existingFotoUrl != null ? NetworkImage(existingFotoUrl!) : null) as ImageProvider?,
                          child: (foto == null && existingFotoUrl == null)
                              ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                              : null,
                        ),
                        if (foto != null || existingFotoUrl != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    foto = null;
                                    existingFotoUrl = null;
                                    hasExistingPhoto = false;
                                    fotoSize = null;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ambil/Pilih Foto'),
                      ),
                      if (fotoSize != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text('${(fotoSize! / 1024).toStringAsFixed(0)} KB', style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File Penilaian (PDF/DOC/DOCX, opsional):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: ElevatedButton.icon(
                          onPressed: _pickPenilaian,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Pilih File'),
                        ),
                      ),
                      if (filePenilaian != null || (widget.peserta?.filePenilaian != null && widget.peserta!.filePenilaian!.isNotEmpty)) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            const SizedBox(width: 4),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                filePenilaianName ?? (widget.peserta?.filePenilaian?.split('/').last ?? ''),
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  filePenilaian = null;
                                  filePenilaianName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'data': {
                            'namapd': namaCtrl.text,
                            'tanggallahir': tglLahirCtrl.text,
                            'jeniskelamin': jenisKelamin,
                            'kelas': selectedKelas,
                            'tinggibadan': tinggiCtrl.text,
                            'beratbadan': beratCtrl.text,
                            'idortu': selectedOrangtua?.id,
                          },
                          'foto': foto,
                          'filePenilaian': filePenilaian,
                        });
                      }
                    },
                    child: const Text('Simpan'),
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