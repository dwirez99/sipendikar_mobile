// form_tambah_siswa.dart
import 'package:flutter/material.dart';

class FormTambahSiswa extends StatefulWidget {
  final Function(Map<String, String>) onSimpan;

  const FormTambahSiswa({required this.onSimpan});

  @override
  State<FormTambahSiswa> createState() => _FormTambahSiswaState();
}

class _FormTambahSiswaState extends State<FormTambahSiswa> {
  final TextEditingController namaCtrl = TextEditingController();
  final TextEditingController ttlCtrl = TextEditingController();
  final TextEditingController ortuCtrl = TextEditingController();
  final TextEditingController alamatCtrl = TextEditingController();
  final TextEditingController tingkatCtrl = TextEditingController();
  final TextEditingController giziCtrl = TextEditingController();

  String selectedKelamin = "Perempuan";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Biodata')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: namaCtrl, decoration: InputDecoration(labelText: 'Nama')),
            TextField(controller: ttlCtrl, decoration: InputDecoration(labelText: 'Tempat Tanggal Lahir')),
            const SizedBox(height: 8),
            Text('Jenis Kelamin'),
            RadioListTile(
              title: Text("Laki-laki"),
              value: "Laki-laki",
              groupValue: selectedKelamin,
              onChanged: (value) => setState(() => selectedKelamin = value.toString()),
            ),
            RadioListTile(
              title: Text("Perempuan"),
              value: "Perempuan",
              groupValue: selectedKelamin,
              onChanged: (value) => setState(() => selectedKelamin = value.toString()),
            ),
            TextField(controller: ortuCtrl, decoration: InputDecoration(labelText: 'Nama Orang Tua')),
            TextField(controller: alamatCtrl, decoration: InputDecoration(labelText: 'Alamat')),
            TextField(controller: tingkatCtrl, decoration: InputDecoration(labelText: 'Tingkat')),
            TextField(controller: giziCtrl, decoration: InputDecoration(labelText: 'Status Gizi')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onSimpan({
                  "nama": namaCtrl.text,
                  "jenisKelamin": selectedKelamin,
                  "ttl": ttlCtrl.text,
                  "ortu": ortuCtrl.text,
                  "alamat": alamatCtrl.text,
                  "tingkat": tingkatCtrl.text,
                  "statusGizi": giziCtrl.text,
                  "foto": "assets/tiara_basori.webp",
                });
                Navigator.pop(context);
              },
              child: Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}
