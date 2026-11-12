import 'package:flutter/material.dart';

Future<String?> promptText(BuildContext context, String title,
        {String initial = ''}) =>
    showDialog<String>(
        context: context,
        builder: (_) => _TextPrompt(title: title, initial: initial));

class _TextPrompt extends StatefulWidget {
  final String title;
  final String initial;
  const _TextPrompt({required this.title, required this.initial});
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

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(
                  labelText: '名称', errorText: _invalid ? '请输入名称' : null)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            FilledButton(
                onPressed: () {
                  if (_controller.text.trim().isEmpty) {
                    setState(() => _invalid = true);
                    return;
                  }
                  Navigator.pop(context, _controller.text.trim());
                },
                child: const Text('保存')),
          ]);
}
