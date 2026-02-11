import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import '../../theme_v2/ozzie_theme.dart';
import 'ozzie_guide_controller.dart';

class OzzieGuideWidget extends StatefulWidget {
  const OzzieGuideWidget({
    super.key,
    this.asset = 'assets/animations/ozzie_guide.riv',
    this.stateMachineName,
    this.initialState = OzzieGuideState.idle,
    this.controller,
    this.enableRive = true,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final String? stateMachineName;
  final OzzieGuideState initialState;
  final OzzieGuideController? controller;
  final bool enableRive;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  State<OzzieGuideWidget> createState() => _OzzieGuideWidgetState();
}

class _OzzieGuideWidgetState extends State<OzzieGuideWidget> {
  late final OzzieGuideController _controller =
      widget.controller ?? OzzieGuideController();
  late final bool _ownsController = widget.controller == null;
  late final Future<void> _assetReadyFuture = _loadAsset();
  bool _forceFallback = false;

  Future<void> _loadAsset() async {
    if (!widget.enableRive) {
      throw FlutterError('Rive disabled for this widget instance.');
    }
    await rootBundle.load(widget.asset);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_forceFallback || !widget.enableRive) {
      return _OzzieGuideFallback(width: widget.width, height: widget.height);
    }

    return FutureBuilder<void>(
      future: _assetReadyFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _OzzieGuideFallback(
            width: widget.width,
            height: widget.height,
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: RiveAnimation.asset(
            widget.asset,
            fit: widget.fit,
            onInit: (artboard) {
              final attached = _controller.attach(
                artboard,
                overrideStateMachineName: widget.stateMachineName,
              );
              if (!attached && mounted) {
                setState(() => _forceFallback = true);
                return;
              }
              _controller.setState(widget.initialState);
            },
          ),
        );
      },
    );
  }
}

class _OzzieGuideFallback extends StatelessWidget {
  const _OzzieGuideFallback({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surfaceAccent,
        shape: BoxShape.circle,
        border: Border.all(color: c.outlineStrong, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.smart_toy_rounded,
        color: c.secondaryPressed,
        size: width < 72 ? 24 : 36,
        semanticLabel: 'Ozzie guide fallback',
      ),
    );
  }
}
