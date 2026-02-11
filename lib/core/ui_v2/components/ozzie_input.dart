import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';

class OzzieInput extends StatefulWidget {
  const OzzieInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.errorText,
    this.focusNode,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final FocusNode? focusNode;

  @override
  State<OzzieInput> createState() => _OzzieInputState();
}

class _OzzieInputState extends State<OzzieInput> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant OzzieInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _internalFocusNode?.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;
    final isFocused = _focusNode.hasFocus;
    final hasError = (widget.errorText ?? '').isNotEmpty;

    final labelColor = hasError
        ? c.danger
        : isFocused
        ? c.secondaryPressed
        : c.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: tokens.type.label.copyWith(color: labelColor),
        ),
        const SizedBox(height: 6),
        Semantics(
          textField: true,
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            style: tokens.type.bodyStrong.copyWith(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
            ),
          ),
        ),
      ],
    );
  }
}
