import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<String?> promptText(
  BuildContext context,
  String title, {
  String initial = '',
  String label = '名称',
  String hint = '',
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _TextPrompt(
        title: title,
        initial: initial,
        label: label,
        hint: hint,
      ),
    );

class _TextPrompt extends StatefulWidget {
  final String title;
  final String initial;
  final String label;
  final String hint;
  const _TextPrompt({
    required this.title,
    required this.initial,
    required this.label,
    required this.hint,
  });
  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initial);
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint.isEmpty ? null : widget.hint,
          errorText: _invalid ? '请输入名称' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
