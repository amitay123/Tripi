import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/tripi_colors.dart';

class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final PageStorageKey? storageKey;

  const ExpandableTextWidget({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.storageKey,
  });

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool _isExpanded = false;
  bool _hasOverflow = false;
  bool _measured = false;

  TextStyle get _textStyle =>
      widget.style ??
      GoogleFonts.inter(
        fontSize: 15,
        color: TripiColors.onSurfaceVariant,
        height: 1.6,
      );

  void _measure(BoxConstraints constraints) {
    if (_measured) return;
    final span = TextSpan(text: widget.text, style: _textStyle);
    final painter = TextPainter(
      text: span,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: constraints.maxWidth);
    final overflow = painter.didExceedMaxLines;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && overflow != _hasOverflow) {
        setState(() {
          _hasOverflow = overflow;
          _measured = true;
        });
      } else {
        _measured = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Restore state from PageStorage
    final bucket = PageStorage.maybeOf(context);
    if (bucket != null && widget.storageKey != null && !_measured) {
      final stored = bucket.readState(context, identifier: widget.storageKey);
      if (stored is bool) _isExpanded = stored;
    }

    return LayoutBuilder(builder: (context, constraints) {
      _measure(constraints);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: Text(
              widget.text,
              style: _textStyle,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
          ),
          if (_hasOverflow)
            GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                if (widget.storageKey != null) {
                  PageStorage.maybeOf(context)?.writeState(
                    context,
                    _isExpanded,
                    identifier: widget.storageKey,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Semantics(
                  button: true,
                  label: _isExpanded
                      ? 'Read less'
                      : 'Read more about this place',
                  excludeSemantics: false,
                  child: Text(
                    _isExpanded ? 'Read less' : 'Read more',
                    style: GoogleFonts.inter(
                      color: TripiColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
