import 'package:flutter/material.dart';
import '../services/base_service.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, BaseBoardService> services;

  const SettingsScreen({super.key, required this.services});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final _dbHelper = DatabaseHelper();
  final Map<String, int> _cutLines = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cutLines = await _dbHelper.getAllCutLines();
    setState(() {
      _cutLines.clear();
      _cutLines.addAll(cutLines);
      for (var service in widget.services.entries) {
        _controllers[service.key] = TextEditingController(
          text: (_cutLines[service.key] ?? 0).toString()
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    for (var entry in _controllers.entries) {
      final cutLine = int.tryParse(entry.value.text) ?? 0;
      await _dbHelper.setCutLine(entry.key, cutLine);
    }
    await _loadSettings();  // 설정 저장 후 다시 로드
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 저장되었습니다')),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '조회수 기준선 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '각 게시판별로 조회수 기준선을 설정할 수 있습니다.\n0으로 설정하면 모든 게시물이 표시됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.services.entries.map((service) {
            return ListTile(
              title: Text(service.value.boardDisplayName),
              subtitle: Text('조회수 ${_cutLines[service.key] ?? 0} 이상'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  controller: _controllers[service.key],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 