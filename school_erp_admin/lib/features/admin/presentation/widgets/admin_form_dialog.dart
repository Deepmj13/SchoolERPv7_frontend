import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/core/widgets/custom_button.dart';

class FormFieldConfig {
  final String key;
  final String label;
  final String? initialValue;
  final bool required;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;
  final List<String>? dropdownOptions;
  final bool isDropdown;
  final bool obscureText;

  FormFieldConfig({
    required this.key,
    required this.label,
    this.initialValue,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator,
    this.dropdownOptions,
    this.isDropdown = false,
    this.obscureText = false,
  });
}

class AdminFormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, String> values) onSave;
  final String submitLabel;

  const AdminFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.submitLabel = 'Save',
  });

  @override
  State<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String> _values;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final f in widget.fields) f.key: f.initialValue ?? '',
    };
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_values);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.fields.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:                 f.isDropdown
                    ? DropdownButtonFormField<String>(
                        initialValue: _values[f.key]!.isEmpty || (f.dropdownOptions?.contains(_values[f.key]) == false)
                            ? null
                            : _values[f.key],
                        decoration: InputDecoration(
                          labelText: f.label,
                          prefixIcon: f.prefixIcon,
                        ),
                        items: (f.dropdownOptions ?? [])
                            .map((o) => DropdownMenuItem(
                                  value: o,
                                  child: Text(o),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _values[f.key] = v ?? ''),
                        validator: f.required && f.validator == null
                            ? (v) =>
                                v == null || v.isEmpty ? '${f.label} required' : null
                            : f.validator,
                      )
                    : TextFormField(
                        initialValue: f.initialValue,
                        keyboardType: f.keyboardType,
                        maxLines: f.maxLines,
                        obscureText: f.obscureText,
                        decoration: InputDecoration(
                          labelText: f.label,
                          prefixIcon: f.prefixIcon,
                        ),
                        onChanged: (v) => _values[f.key] = v,
                        validator: f.required && f.validator == null
                            ? (v) =>
                                v == null || v.trim().isEmpty
                                    ? '${f.label} required'
                                    : null
                            : f.validator,
                      ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        CustomButton(
          label: widget.submitLabel,
          loading: _saving,
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
