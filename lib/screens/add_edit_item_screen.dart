import 'package:flutter/material.dart';
import 'package:smartpack/db/database_helper.dart';

class AddEditItemScreen extends StatefulWidget {
  final int tripId;
  final Map<String, dynamic>? item; // null = tambah, ada = edit

  const AddEditItemScreen({
    super.key,
    required this.tripId,
    this.item,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: "1");

  String _category = "Umum";
  final List<String> _categories = [
    "Umum",
    "Pakaian",
    "Dokumen",
    "Elektronik",
    "Toiletries",
    "Obat",
  ];

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = (widget.item!['name'] ?? '').toString();
      _qtyController.text = (widget.item!['qty'] ?? 1).toString();
      _category = (widget.item!['category'] ?? 'Umum').toString();
      if (!_categories.contains(_category)) _category = "Umum";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama barang tidak boleh kosong & jumlah harus > 0")),
      );
      return;
    }

    try {
      if (isEdit) {
        final id = widget.item!['id'] as int;
        await DatabaseHelper.instance.updateItem(id, {
          'name': name,
          'qty': qty,
          'category': _category,
        });
      } else {
        await DatabaseHelper.instance.insertItem({
          'tripId': widget.tripId,
          'name': name,
          'category': _category,
          'qty': qty,
          'isChecked': 0,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Barang" : "Tambah Barang"),
        backgroundColor: const Color(0xFF1ABC9C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nama Barang",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? "Umum"),
              decoration: InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: Text(isEdit ? "Simpan Perubahan" : "Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
