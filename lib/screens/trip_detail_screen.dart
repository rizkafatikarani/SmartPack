import 'package:flutter/material.dart';
import 'package:smartpack/db/database_helper.dart';
import 'package:smartpack/screens/add_edit_item_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  final String title;
  final String destination;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.title,
    required this.destination,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<Map<String, dynamic>> _items = [];

  // Template checklist (Fungsional #5)
  final Map<String, List<Map<String, dynamic>>> _templates = {
    "Liburan": [
      {"name": "Baju", "qty": 3, "category": "Pakaian"},
      {"name": "Celana", "qty": 2, "category": "Pakaian"},
      {"name": "Jaket", "qty": 1, "category": "Pakaian"},
      {"name": "Sandal", "qty": 1, "category": "Pakaian"},
      {"name": "Charger HP", "qty": 1, "category": "Elektronik"},
      {"name": "Powerbank", "qty": 1, "category": "Elektronik"},
      {"name": "Sikat gigi", "qty": 1, "category": "Toiletries"},
      {"name": "Pasta gigi", "qty": 1, "category": "Toiletries"},
    ],
    "Kerja/Meeting": [
      {"name": "Laptop", "qty": 1, "category": "Elektronik"},
      {"name": "Charger Laptop", "qty": 1, "category": "Elektronik"},
      {"name": "Kartu Identitas", "qty": 1, "category": "Dokumen"},
      {"name": "Dompet", "qty": 1, "category": "Dokumen"},
      {"name": "Notebook", "qty": 1, "category": "Umum"},
      {"name": "Pulpen", "qty": 2, "category": "Umum"},
    ],
    "Camping": [
      {"name": "Tenda", "qty": 1, "category": "Umum"},
      {"name": "Sleeping bag", "qty": 1, "category": "Umum"},
      {"name": "Senter", "qty": 1, "category": "Elektronik"},
      {"name": "Baterai cadangan", "qty": 2, "category": "Elektronik"},
      {"name": "Jas hujan", "qty": 1, "category": "Pakaian"},
      {"name": "Obat pribadi", "qty": 1, "category": "Obat"},
    ],
  };

  void _loadItems() async {
    final data = await DatabaseHelper.instance.getItemsByTrip(widget.tripId);
    if (!mounted) return;
    setState(() => _items = data);
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _openAddItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditItemScreen(tripId: widget.tripId),
      ),
    );
    if (result == true) _loadItems();
  }

  Future<void> _openEditItem(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditItemScreen(
          tripId: widget.tripId,
          item: item,
        ),
      ),
    );
    if (result == true) _loadItems();
  }

  void _toggleChecked(Map<String, dynamic> item) async {
    final newValue = (item['isChecked'] == 1) ? 0 : 1;
    await DatabaseHelper.instance.updateItemChecked(item['id'], newValue);
    _loadItems();
  }

  void _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteItem(id);
    _loadItems();
  }

  // pilih template + insert batch
  Future<void> _showTemplatePicker() async {
  final chosen = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Pilih Template Checklist"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _templates.keys.map((key) {
            return ListTile(
              title: Text(key),
              onTap: () => Navigator.pop(context, key),
            );
          }).toList(),
        ),
      );
    },
  );

  if (chosen == null) return;

  final templateItems = _templates[chosen]!;

  // cek apakah salah satu item dari template sudah ada di trip ini
  final existingNames = _items.map((e) => e['name'].toString()).toSet();

  final alreadyUsed = templateItems.any(
    (e) => existingNames.contains(e['name']),
  );

  if (alreadyUsed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Template '$chosen' sudah digunakan untuk trip ini"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final itemsToInsert = templateItems
      .map((e) => {
            "tripId": widget.tripId,
            "name": e["name"],
            "qty": e["qty"],
            "category": e["category"],
            "isChecked": 0,
          })
      .toList();

  await DatabaseHelper.instance.insertItemsBatch(itemsToInsert);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Template '$chosen' berhasil ditambahkan")),
  );

  _loadItems();
}


  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.where((e) => e['isChecked'] == 1).length;
    final total = _items.length;

    // Progress Packing (Fungsional #4)
    final progress = total == 0 ? 0.0 : (checkedCount / total);
    final percent = (progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1ABC9C),
        actions: [
          IconButton(
            tooltip: "Pakai Template",
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showTemplatePicker,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItem,
        backgroundColor: const Color(0xFF1ABC9C),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.destination,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              "Checklist: $checkedCount / $total",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE8F7F3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1ABC9C)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Progress Packing: $percent%",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text("Belum ada barang"))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        final isChecked = item['isChecked'] == 1;
                        final category = (item['category'] ?? 'Umum').toString();

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isChecked,
                              onChanged: (_) => _toggleChecked(item),
                              activeColor: const Color(0xFF1ABC9C),
                            ),
                            title: Text(
                              "${item['name']} (x${item['qty']})",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration:
                                    isChecked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F7F3),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1ABC9C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: "Edit",
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _openEditItem(item),
                                ),
                                IconButton(
                                  tooltip: "Hapus",
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteItem(item['id']),
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
    );
  }
}
