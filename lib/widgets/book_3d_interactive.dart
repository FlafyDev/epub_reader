import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'book_3d.dart';

class Book3dInteractive extends StatefulWidget {
  const Book3dInteractive({
    Key? key,
    this.pageDepth = 2.0,
    required this.book3dData,
    this.onRotationChanged,
    this.borderRadius,
    this.spreadRadius,
  }) : super(key: key);

  final Book3DData book3dData;
  final void Function(double)? onRotationChanged;
  final double pageDepth;
  final BorderRadius? borderRadius;
  final double? spreadRadius;

  @override
  _Book3dInteractiveState createState() => _Book3dInteractiveState();
}

class _Book3dInteractiveState extends State<Book3dInteractive>
    with SingleTickerProviderStateMixin {
  double rotateY = 0;
  late AnimationController _rotateController;
  bool _isFriction = false;

  @override
  void initState() {
    _rotateController = AnimationController.unbounded(
        vsync: this, duration: const Duration(seconds: 2));
    _rotateController.addListener(() {
      widget.onRotationChanged?.call(_rotateController.value);
      if (_isFriction && _rotateController.velocity.abs() < 0.05) {
        _isFriction = false;
        _rotateController.stop();
        _rotateController.animateWith(SpringSimulation(
          const SpringDescription(damping: 1, mass: 10, stiffness: 1),
          _rotateController.value % (pi * 2),
          _rotateController.value % (pi * 2) > pi ? pi * 2 : 0,
          0.01,
        ));
      }
    });
    super.initState();
  }

  @override
  dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _rotateController.stop();
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _rotateController.value -= details.delta.dx * 0.005;
        });
      },
      onHorizontalDragEnd: (details) {
        _isFriction = true;
        _rotateController.animateWith(FrictionSimulation(
          0.1,
          _rotateController.value,
          -details.velocity.pixelsPerSecond.dx / 200,
        ));
      },
      child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, w) {
            return Container(
              color: Colors.transparent,
              child: Center(
                child: Book3D(
                  book3dData: widget.book3dData,
                  rotateY: _rotateController.value,
                  pageDepth: widget.pageDepth,
                  borderRadius: widget.borderRadius,
                  spreadRadius: widget.spreadRadius,
                ),
              ),
            );
          }),
    );
  }
}
