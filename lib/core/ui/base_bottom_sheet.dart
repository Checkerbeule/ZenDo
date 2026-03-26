import 'package:flutter/material.dart';

class BaseBottomSheet extends StatelessWidget {
  final Widget? header;
  final Widget? body;
  final Widget? footer;
  final double? maxHeight;

  const BaseBottomSheet({
    super.key,
    this.header,
    this.body,
    this.footer,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              (maxHeight?.clamp(0.0, 1.0) ?? 0.95),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draghandle
              Center(
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              //Header
              if (header != null) header!,
              // Body
              if (body != null)
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 5),
                      child: body!,
                    ),
                  ),
                ),
              // Footer
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}
