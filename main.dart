import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const FoodInspectorApp());
}

class FoodInspectorApp extends StatelessWidget {
  const FoodInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مفتش الأغذية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('inspection_records');
    if (data != null) {
      setState(() {
        _records = List<Map<String, dynamic>>.from(json.decode(data));
        _filteredRecords = _records;
      });
    }
  }

  Future<void> _saveRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _records.insert(0, record);
      _filteredRecords = _records;
    });
    await prefs.setString('inspection_records', json.encode(_records));
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((r) {
          return r['name'].toString().contains(query) ||
              r['owner'].toString().contains(query) ||
              r['license'].toString().contains(query);
        }).toList();
      }
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final nationalIdCtrl = TextEditingController();
    final healthCertCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final violationsCtrl = TextEditingController();
    String type = 'مطعم';
    String action = 'استيفاء الشروط / صالحة';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل فحص منشأة جديدة', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنشأة *')),
              DropdownButtonFormField<String>(
                value: type,
                items: ['مطعم', 'سوبر ماركت', 'مصنع أغذية', 'مخبز', 'نشاط آخر']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => type = v!,
                decoration: const InputDecoration(labelText: 'نوع النشاط'),
              ),
              TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'اسم المسؤول / المالك')),
              TextField(controller: nationalIdCtrl, decoration: const InputDecoration(labelText: 'الرقم القومي'), keyboardType: TextInputType.number),
              TextField(controller: healthCertCtrl, decoration: const InputDecoration(labelText: 'رقم الشهادة الصحية')),
              TextField(controller: licenseCtrl, decoration: const InputDecoration(labelText: 'رقم الرخصة')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: violationsCtrl, decoration: const InputDecoration(labelText: 'المخالفات إن وجدت')),
              DropdownButtonFormField<String>(
                value: action,
                items: [
                  'استيفاء الشروط / صالحة',
                  'سحب عينات للفحص',
                  'محضر إعدام مواد غير صالحة',
                  'توجيه إنذار',
                  'طلب غلق إداري'
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => action = v!,
                decoration: const InputDecoration(labelText: 'الإجراء المتخذ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              _saveRecord({
                'id': DateTime.now().millisecondsSinceEpoch,
                'name': nameCtrl.text,
                'type': type,
                'owner': ownerCtrl.text,
                'nationalId': nationalIdCtrl.text,
                'healthCert': healthCertCtrl.text,
                'license': licenseCtrl.text,
                'address': addressCtrl.text,
                'violations': violationsCtrl.text,
                'action': action,
                'date': DateTime.now().toString().split(' ')[0],
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق مفتش الأغذية'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: const InputDecoration(
                labelText: 'بحث باسم المنشأة أو الرخصة...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredRecords.isEmpty
                ? const Center(child: Text('لا توجد سجلات مسجلة بعد.'))
                : ListView.builder(
                    itemCount: _filteredRecords.length,
                    itemBuilder: (ctx, idx) {
                      final r = _filteredRecords[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r['type']} | المسؤول: ${r['owner']}\nالإجراء: ${r['action']}'),
                          trailing: Text(r['date'] ?? ''),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
