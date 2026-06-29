import 'package:flutter/material.dart';
import 'package:school_erp_admin/core/theme/app_colors.dart';
import 'package:school_erp_admin/features/admin/presentation/widgets/admin_form_dialog.dart';

class AdminFormSheet extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, String> values) onSave;
  final String submitLabel;

  const AdminFormSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.submitLabel = 'Save',
  });

  @override
  State<AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends State<AdminFormSheet> {
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ...widget.fields.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: f.isDropdown
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
              }),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saving ? null : _handleSave,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.submitLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
