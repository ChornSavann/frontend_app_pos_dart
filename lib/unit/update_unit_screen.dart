import 'package:flutter/material.dart';
import 'package:pos_inventory/models/Unit.dart';
import '../api/api_unit.dart';


class UpdateUnitScreen extends StatefulWidget {
  final UnitModel unit; // 👈 ទទួល Unit Object ដែលត្រូវកែប្រែ

  const UpdateUnitScreen({super.key, required this.unit});

  @override
  State<UpdateUnitScreen> createState() => _UpdateUnitScreenState();
}

class _UpdateUnitScreenState extends State<UpdateUnitScreen> {
  final _formKey = GlobalKey<FormState>();

  // 📝 Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _valueController;

  // 🔄 State
  int? _selectedBaseUnitId;
  String? _selectedOperator;
  bool _isLoading = false;

  List<UnitModel> _baseUnits = [];
  bool _isLoadingUnits = true;

  final List<Map<String, String>> _operators = [
    {'label': 'Multiply (*)', 'value': '*'},
    {'label': 'Divide (/)', 'value': '/'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit.name);
    _shortNameController = TextEditingController(text: widget.unit.shortName);
    _valueController = TextEditingController(text: widget.unit.value?.toString() ?? '');

    _selectedBaseUnitId = widget.unit.baseUnitId;
    _selectedOperator = widget.unit.operator;

    _loadBaseUnits();
  }

  Future<void> _loadBaseUnits() async {
    try {
      final units = await ApiUnit().fetchUnits();
      if (mounted) {
        setState(() {
          _baseUnits = units.where((u) => u.id != widget.unit.id).toList();
          _isLoadingUnits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUnits = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

// 💾 Function សម្រាប់ Update ទិន្នន័យទៅកាន់ API
  Future<void> _updateUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final unitData = {
      'name': _nameController.text.trim(),
      'short_name': _shortNameController.text.trim(),
      'base_unit_id': _selectedBaseUnitId,
      'operator': _selectedOperator,
      'value': _valueController.text.isNotEmpty
          ? double.tryParse(_valueController.text)
          : null,
    };

    // 🚀 ហៅ API Update Unit
    final result = await ApiUnit().updateUnit(widget.unit.id!, unitData);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // ✨ បង្ហាញ Success Dialog ស្អាត
      _showSuccessDialog(
        result['message'] ?? 'Unit updated successfully!',
        onDeleteOrClose: () {
          Navigator.pop(context, true); // ត្រឡប់ទៅអេក្រង់មុននិង Refresh
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update unit'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// ✨ Function សម្រាប់បង្ហាញ Success Dialog ស្អាតបែប Modern
  void _showSuccessDialog(String message, {VoidCallback? onDeleteOrClose}) {
    showDialog(
      context: context,
      barrierDismissible: false, // មិនឱ្យចុចបិទផ្ទាំងខាងក្រៅបានទេ ទាល់តែចុច OK
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Success!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // បិទ Dialog សិន
                    if (onDeleteOrClose != null) {
                      onDeleteOrClose(); // បន្ទាប់មកបញ្ជូនត្រឡប់ក្រោយនិង Refresh
                    }
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Update Unit",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Unit Information",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // 🏷️ Unit Name
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  'Unit Name (e.g. Box, Kilogram)',
                  Icons.straighten,
                ),
                validator: (v) =>
                v!.isEmpty ? 'Unit name is required' : null,
              ),
              const SizedBox(height: 16),

              // 🔤 Short Name
              TextFormField(
                controller: _shortNameController,
                decoration: _inputDecoration(
                  'Short Name (e.g. Box, Kg, Pcs)',
                  Icons.short_text,
                ),
                validator: (v) =>
                v!.isEmpty ? 'Short name is required' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                "Sub-Unit Relationship (Optional)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Use this if this unit depends on a base unit (e.g., 1 Box = 12 Pcs)",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // 🔗 Base Unit Dropdown
              _isLoadingUnits
                  ? DropdownButtonFormField<int>(
                value: null,
                decoration: _inputDecoration('Loading base units...', Icons.link),
                items: const [],
                onChanged: null,
              )
                  : DropdownButtonFormField<int>(
                value: _selectedBaseUnitId,
                decoration: _inputDecoration(
                  'Base Unit (Optional)',
                  Icons.link,
                  suffixIcon: _selectedBaseUnitId != null
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedBaseUnitId = null;
                        _selectedOperator = null;
                        _valueController.clear();
                      });
                    },
                  )
                      : null,
                ),
                items: _baseUnits.map((unit) {
                  return DropdownMenuItem<int>(
                    value: unit.id,
                    child: Text("${unit.name} (${unit.shortName})"),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedBaseUnitId = newValue;
                    if (newValue == null) {
                      _selectedOperator = null;
                      _valueController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // ➗ Operator & Value Field (បង្ហាញលុះត្រាតែមានការរើស Base Unit)
              if (_selectedBaseUnitId != null) ...[
                DropdownButtonFormField<String>(
                  value: _selectedOperator,
                  decoration: _inputDecoration(
                    'Operator (e.g. *)',
                    Icons.calculate_outlined,
                  ),
                  items: _operators.map((op) {
                    return DropdownMenuItem<String>(
                      value: op['value'],
                      child: Text(op['label']!),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedOperator = val),
                  validator: (v) => _selectedBaseUnitId != null && (v == null || v.isEmpty)
                      ? 'Operator is required'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    'Value / Multiplier (e.g. 12)',
                    Icons.exposure,
                  ),
                  validator: (v) => _selectedBaseUnitId != null && (v == null || v.isEmpty)
                      ? 'Value is required'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // 💾 Update Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _updateUnit,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.update_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Update Unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}