import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ManageArticleForm extends StatefulWidget {
  final Map<String, dynamic>? article;
  final Function(Map<String, dynamic> data, File? thumbnail) onSubmit;
  final bool isEdit;

  const ManageArticleForm({
    Key? key,
    this.article,
    required this.onSubmit,
    this.isEdit = false,
  }) : super(key: key);

  @override
  _ManageArticleFormState createState() => _ManageArticleFormState();
}

class _ManageArticleFormState extends State<ManageArticleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  File? _thumbnail;
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?['title'] ?? '');
    if (widget.article?['content'] != null && widget.article!['content'].toString().isNotEmpty) {
      _quillController = quill.QuillController(
        document: quill.Document()..insert(0, widget.article!['content'].toString()),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = quill.QuillController.basic();
    }
    _thumbnailUrl = widget.article?['thumbnail'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _thumbnail = File(picked.path);
        _thumbnailUrl = null; // pastikan url direset agar preview update
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await widget.onSubmit({
          'title': _titleController.text,
          'content': _quillController.document.toPlainText().trim(),
          'thumbnail': _thumbnailUrl,
        }, _thumbnail);
        Navigator.pop(context); // close loading
        Navigator.pop(context, true); // close form and trigger reload
      } catch (e) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kegiatan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (value) => value == null || value.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Konten Kegiatan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              quill.QuillSimpleToolbar(controller: _quillController),
              Container(
                height: 200,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  focusNode: FocusNode(),
                  scrollController: ScrollController(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickThumbnail,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Thumbnail'),
                  ),
                  const SizedBox(width: 16),
                  if (_thumbnail != null)
                    Image.file(_thumbnail!, width: 60, height: 60, fit: BoxFit.cover)
                  else if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
                    Image.network(_thumbnailUrl!, width: 60, height: 60, fit: BoxFit.cover)
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.isEdit ? 'Simpan Perubahan' : 'Tambah Kegiatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
