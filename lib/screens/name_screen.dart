import 'package:flutter/material.dart';
import '../database/name_database_helper.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final NameDatabaseHelper _dbHelper = NameDatabaseHelper();
  
  final _nameController = TextEditingController();
  final _comController = TextEditingController();
  final _zaController = TextEditingController();

  final _comFocus = FocusNode();
  final _zaFocus = FocusNode();

  List<Map<String, dynamic>> _itemsList = [];
  int _editingId = -1;
  String _originalName = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _comController.dispose();
    _zaController.dispose();
    _comFocus.dispose();
    _zaFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _dbHelper.getAllNames();
    setState(() {
      _itemsList = data;
    });
  }

  Future<void> _saveItem() async {
    String name = _nameController.text.trim();
    String comStr = _comController.text.trim();
    String zaStr = _zaController.text.trim();

    if (name.isEmpty || comStr.isEmpty || zaStr.isEmpty) {
      _showSnackBar("အားလုံးဖြည့်ရန်", Colors.red);
      return;
    }

    int com = int.tryParse(comStr) ?? -1;
    int za = int.tryParse(zaStr) ?? -1;

    if (com == -1 || za == -1) {
      _showSnackBar("ကော်နှင့်အဆကို ဂဏန်းဖြည့်ရန်", Colors.red);
      return;
    }

    if (_editingId != -1) {
      if (name != _originalName && await _dbHelper.checkNameExists(name)) {
        _showSnackBar("ဤအမည်ရှိပြီးသား", Colors.red);
        return;
      }
      bool updated = await _dbHelper.updateName(_editingId, name, com, za);
      if (updated) {
        _showSnackBar("ပြင်ဆင်ပြီး", Colors.green);
        _resetForm();
        _loadData();
      }
    } else {
      if (await _dbHelper.checkNameExists(name)) {
        _showSnackBar("ဤအမည်ရှိပြီးသား", Colors.red);
        return;
      }
      int result = await _dbHelper.insertName(name, com, za);
      if (result != -1) {
        _showSnackBar("ထည့်သွင်းပြီး", Colors.green);
        _resetForm();
        _loadData();
      }
    }
  }

  void _editItem(Map<String, dynamic> item) {
    setState(() {
      _editingId = item['id'];
      _originalName = item['name'];
      _nameController.text = item['name'];
      _comController.text = item['com'].toString();
      _zaController.text = item['za'].toString();
    });
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    if (item['name'] == 'Admin') {
      _showSnackBar("Admin ကိုဖျက်၍မရပါ", Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ဖျက်ရန် အတည်ပြုခြင်း"),
        content: Text('"${item['name']}" ကိုဖျက်မှာသေချာလား?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("မဖျက်တော့ပါ")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool deleted = await _dbHelper.deleteName(item['id']);
              if (deleted) {
                _showSnackBar("ဖျက်ပြီးပါပြီ", Colors.green);
                if (_editingId == item['id']) _resetForm();
                _loadData();
              }
            },
            child: const Text("ဖျက်မည်", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _editingId = -1;
      _originalName = "";
      _nameController.clear();
      _comController.clear();
      _zaController.clear();
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ဝယ်သူစာရင်း စီမံခြင်း"), backgroundColor: const Color(0xFFC53030)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'အမည်'),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_comFocus),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comController,
                            focusNode: _comFocus,
                            decoration: const InputDecoration(labelText: 'ကော်မရှင် %'),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(context).requestFocus(_zaFocus),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _zaController,
                            focusNode: _zaFocus,
                            decoration: const InputDecoration(labelText: 'အဆMultiplier'),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _saveItem(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC53030)),
                      child: Text(_editingId != -1 ? "ပြင်ဆင်မည်" : "ထည့်မည်", style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              color: const Color(0xFF1976D2),
              padding: const EdgeInsets.all(10),
              child: const Row(
                children: [
                  Expanded(child: Text("အမည်", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(child: Text("ကော်", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(child: Text("အဆ", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                  Expanded(child: Text("Action", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _itemsList.length,
                itemBuilder: (context, index) {
                  final item = _itemsList[index];
                  bool isAdmin = item['name'] == 'Admin';
                  return Container(
                    color: const Color(0xFFE3F2FD),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text(item['name'], textAlign: TextAlign.center)),
                        Expanded(child: Text(item['com'].toString(), textAlign: TextAlign.center)),
                        Expanded(child: Text(item['za'].toString(), textAlign: TextAlign.center)),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.green, size: 20), onPressed: () => _editItem(item)),
                              IconButton(
                                icon: Icon(Icons.delete, color: isAdmin ? Colors.grey : Colors.red, size: 20),
                                onPressed: isAdmin ? null : () => _deleteItem(item),
                              ),
                            ],
                          ),
                        ),
                      ],
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