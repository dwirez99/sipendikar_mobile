import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DaftarSiswaPage extends StatefulWidget {
  const DaftarSiswaPage({super.key});

  @override
  State<DaftarSiswaPage> createState() => _DaftarSiswaPageState();
}

class _DaftarSiswaPageState extends State<DaftarSiswaPage> {
  final List<Map<String, String>> _dataSiswa = [];

  final _namaCtrl = TextEditingController();
  final _tempatLahirCtrl = TextEditingController();
  final _tglLahirCtrl = TextEditingController();
  final _ortuCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _giziCtrl = TextEditingController();

  String _selectedKelamin = "Laki-laki";
  String _selectedSemester = "Ganjil";
  String _selectedTingkat = "TK A";

  File? _imageFile;
  String? _webImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = File(picked.path);
        _webImage = base64Encode(bytes);
      });
    }
  }

  Widget _getImageWidget() {
    if (_webImage != null) {
      return Image.memory(base64Decode(_webImage!), fit: BoxFit.cover);
    } else if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.image, size: 50, color: Colors.grey);
    }
  }

  void _simpanData() {
    if (_namaCtrl.text.isEmpty ||
        _tempatLahirCtrl.text.isEmpty ||
        _tglLahirCtrl.text.isEmpty ||
        _ortuCtrl.text.isEmpty ||
        _alamatCtrl.text.isEmpty ||
        _giziCtrl.text.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Validasi Gagal"),
          content: const Text("Semua field harus diisi sebelum menyimpan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _dataSiswa.add({
        "nama": _namaCtrl.text,
        "jenisKelamin": _selectedKelamin,
        "ttl": "${_tempatLahirCtrl.text}, ${_tglLahirCtrl.text}",
        "ortu": _ortuCtrl.text,
        "alamat": _alamatCtrl.text,
        "semester": _selectedSemester,
        "tingkat": _selectedTingkat,
        "statusGizi": _giziCtrl.text,
        "foto": _imageFile?.path ?? "",
        "webImage": _webImage ?? "",
      });

      _resetForm();
    });

    Navigator.pop(context);
  }

  void _resetForm() {
    _namaCtrl.clear();
    _tempatLahirCtrl.clear();
    _tglLahirCtrl.clear();
    _ortuCtrl.clear();
    _alamatCtrl.clear();
    _giziCtrl.clear();
    _selectedKelamin = "Laki-laki";
    _selectedSemester = "Ganjil";
    _selectedTingkat = "TK A";
    _imageFile = null;
    _webImage = null;
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRadioGroup(String title, List<String> options, String selected, void Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...options.map((opt) => RadioListTile(
                title: Text(opt),
                value: opt,
                groupValue: selected,
                onChanged: (val) => setState(() => onChanged(val as String)),
              )),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _tglLahirCtrl,
        decoration: const InputDecoration(
          labelText: "Tanggal Lahir",
          border: OutlineInputBorder(),
        ),
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _tglLahirCtrl.text = DateFormat("dd-MM-yyyy").format(picked);
          }
        },
      ),
    );
  }

  Widget _buildCard(Map<String, String> siswa) {
    final fotoPath = siswa["foto"] ?? "";
    final webImage = siswa["webImage"] ?? "";

    final imageWidget = webImage.isNotEmpty
        ? Image.memory(base64Decode(webImage), width: 100, height: 120, fit: BoxFit.cover)
        : (fotoPath.isNotEmpty
            ? Image.file(File(fotoPath), width: 100, height: 120, fit: BoxFit.cover)
            : const Icon(Icons.image, size: 100, color: Colors.grey));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            imageWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(siswa["nama"] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("JK: ${siswa["jenisKelamin"]}"),
                  Text("TTL: ${siswa["ttl"]}"),
                  Text("Ortu: ${siswa["ortu"]}"),
                  Text("Alamat: ${siswa["alamat"]}"),
                  Text("Semester: ${siswa["semester"]}"),
                  Text("Tingkat: ${siswa["tingkat"]}"),
                  Text("Gizi: ${siswa["statusGizi"]}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTambahDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _getImageWidget(),
                    ),
                  ),
                ),
                _buildTextField(_namaCtrl, "Nama"),
                _buildTextField(_tempatLahirCtrl, "Tempat Lahir"),
                _buildDatePicker(),
                _buildRadioGroup("Jenis Kelamin", ["Laki-laki", "Perempuan"], _selectedKelamin, (val) => _selectedKelamin = val),
                _buildTextField(_ortuCtrl, "Nama Orang Tua"),
                _buildTextField(_alamatCtrl, "Alamat"),
                _buildRadioGroup("Semester", ["Ganjil", "Genap"], _selectedSemester, (val) => _selectedSemester = val),
                _buildRadioGroup("Tingkat", ["TK A", "TK B"], _selectedTingkat, (val) => _selectedTingkat = val),
                _buildTextField(_giziCtrl, "Status Gizi"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                    ElevatedButton(onPressed: _simpanData, child: const Text("Simpan")),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Data Siswa")),
        floatingActionButton: FloatingActionButton(
          onPressed: _showTambahDialog,
          child: const Icon(Icons.add),
        ),
        body: _dataSiswa.isEmpty
            ? const Center(child: Text("Belum ada data siswa"))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _dataSiswa.length,
                itemBuilder: (context, index) => _buildCard(_dataSiswa[index]),
              ),
      ),
    );
  }
}
