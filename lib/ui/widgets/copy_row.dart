import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyRow extends StatelessWidget {
  const CopyRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = true,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                value.isEmpty ? '（未设置）' : value,
                style: mono
                    ? const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4)
                    : null,
              ),
            ),
            IconButton(
              tooltip: '复制',
              onPressed: value.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制')),
                        );
                      }
                    },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
