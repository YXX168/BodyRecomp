import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sheet_frame.dart';

Future<Map<String, double>?> editBodyValues(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
  required Map<String, double> initial,
  String? subtitle,
}) =>
    showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BodyEditor(
        title: title,
        fields: fields,
        initial: initial,
        subtitle: subtitle,
      ),
    );

class _BodyEditor extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Map<String, String> fields;
  final Map<String, double> initial;
  const _BodyEditor({
    required this.title,
    required this.fields,
    required this.initial,
    this.subtitle,
  });
  @override
  State<_BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends State<_BodyEditor> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {
    for (final field in widget.fields.keys)
      field:
          TextEditingController(text: widget.initial[field]?.toString() ?? '')
  };
  bool _empty = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_empty) setState(() => _empty = false);
    if (!_form.currentState!.validate()) return;
    final values = {
      for (final entry in _controllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: double.parse(entry.value.text.trim())
    };
    if (values.isEmpty) {
      setState(() => _empty = true);
      return;
    }
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SheetFrame(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: Icons.straighten_rounded,
      body: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in widget.fields.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  key: ValueKey('body-value-${field.key}'),
                  controller: _controllers[field.key],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: field.key == widget.fields.keys.last
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onFieldSubmitted: field.key == widget.fields.keys.last
                      ? (_) => _save()
                      : null,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: field.value,
                    hintText: widget.fields.length > 1 ? '选填' : '请输入数值',
                  ),
                  validator: (text) {
                    final raw = text?.trim() ?? '';
                    if (raw.isEmpty && widget.fields.length > 1) {
                      return null;
                    }
                    final value = double.tryParse(raw);
                    return value == null || !value.isFinite || value <= 0
                        ? '请输入大于 0 的有效数字'
                        : null;
                  },
                ),
              ),
            if (_empty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '请至少填写一项围度',
                  style: TextStyle(color: p.danger, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              key: const Key('save-body-values'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
