import 'dart:async';

import 'package:ardrive_ui_library/ardrive_ui_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

class ArDriveDropdown extends StatefulWidget {
  const ArDriveDropdown({
    super.key,
    required this.items,
    required this.child,
    // required this.controller,
    this.contentPadding,
    this.height = 60,
    this.width = 400,
  });

  final double height;
  final double width;
  final List<ArDriveDropdownItem> items;
  final Widget child;
  // final ArDriveOverlayController controller;
  final EdgeInsets? contentPadding;

  @override
  State<ArDriveDropdown> createState() => _ArDriveDropdownState();
}

class _ArDriveDropdownState extends State<ArDriveDropdown> {
  @override
  Widget build(BuildContext context) {
    double dropdownHeight = widget.items.length * widget.height;
    dropdownHeight = (widget.contentPadding?.top ?? 8) + dropdownHeight;
    dropdownHeight = (widget.contentPadding?.bottom ?? 8) + dropdownHeight;

    return ArDriveOverlay(
      // controller: widget.controller,
      content: TweenAnimationBuilder<double>(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        tween: Tween(begin: 50, end: dropdownHeight),
        builder: (context, size, _) {
          return SizedBox(
            height: size,
            width: 300,
            child: ArDriveCard(
              content: Column(
                  children: List.generate(widget.items.length, (index) {
                return FutureBuilder<bool>(
                    future: Future.delayed(
                      Duration(milliseconds: (index + 1) * 50),
                      () => true,
                    ),
                    builder: (context, snapshot) {
                      return AnimatedCrossFade(
                        duration: const Duration(milliseconds: 100),
                        firstChild: SizedBox(
                          width: widget.width,
                          height: widget.height,
                          child: widget.items[index],
                        ),
                        secondChild: SizedBox(
                          height: 0,
                          width: widget.width,
                        ),
                        crossFadeState: snapshot.hasData && snapshot.data!
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                      );
                    });
              })),
              boxShadow: BoxShadowCard.shadow80,
            ),
          );
        },
      ),
      child: widget.child,
    );
  }
}

class ArDriveOverlay extends StatefulWidget {
  const ArDriveOverlay({
    super.key,
    required this.content,
    this.contentPadding = const EdgeInsets.all(16),
    required this.child,
    // required this.controller,
  });

  final Widget child;
  final Widget content;
  final EdgeInsets contentPadding;
  // final ArDriveOverlayController controller;

  @override
  State<ArDriveOverlay> createState() => _ArDriveOverlayState();
}

abstract class ArDriveOverlayController {
  factory ArDriveOverlayController() = _ArDriveOverlayController;
  void show();
  void hide();

  bool get isShowing;

  StreamController<bool> get controller;
}

class _ArDriveOverlayController implements ArDriveOverlayController {
  bool _isShowing = false;

  @override
  void hide() {
    _isShowing = false;
    _controller.sink.add(_isShowing);
  }

  @override
  void show() {
    _isShowing = true;
    _controller.sink.add(_isShowing);
  }

  @override
  StreamController<bool> get controller => _controller;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isShowing => _isShowing;
}

class _ArDriveOverlayState extends State<ArDriveOverlay> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Portal(
        child: PortalTarget(
      visible: _visible,
      portalFollower: widget.content,
      anchor: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.topRight,
      ),
      child: GestureDetector(
          onTap: () {
            setState(() {
              _visible = true;
            });
          },
          child: widget.child),
    ));
  }
}

class ArDriveDropdownItem extends StatelessWidget {
  const ArDriveDropdownItem({
    super.key,
    required this.content,
  });

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: content,
    );
  }
}
