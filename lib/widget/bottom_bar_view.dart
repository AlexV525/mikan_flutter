import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mikan_flutter/internal/extension.dart';
import 'package:mikan_flutter/topvars.dart';
import 'package:mikan_flutter/widget/ripple_tap.dart';

class BarItem {
  IconData? icon;
  IconData? selectedIcon;
  String? iconPath;
  String? selectedIconPath;
  VoidCallback? onClick;
  bool isSelected;
  int _index = 0;
  double _size = 0;

  BarItem({
    this.icon,
    this.selectedIcon,
    this.iconPath,
    this.selectedIconPath,
    this.onClick,
    this.isSelected = false,
  });
}

class BottomBarView extends StatefulWidget {
  const BottomBarView({
    Key? key,
    required this.items,
    required this.onItemClick,
    this.height = 56.0,
    this.iconSize = 28.0,
  })  : assert(height > iconSize),
        super(key: key);

  final Function(int index) onItemClick;
  final List<BarItem> items;
  final double height;
  final double iconSize;

  @override
  BottomBarViewState createState() => BottomBarViewState();
}

class BottomBarViewState extends State<BottomBarView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bgc = Theme.of(context).backgroundColor;
    return ClipRRect(
      borderRadius: borderRadius16,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgc.withOpacity(0.9),
            boxShadow: [
              BoxShadow(color: bgc.withOpacity(0.1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildBarItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBarItems() {
    return List.generate(
      widget.items.length,
      (i) {
        widget.items[i]._index = i;
        widget.items[i]._size = widget.iconSize;
        return _BottomBarItemView(
          barItem: widget.items[i],
          removeAllSelect: () {
            widget.onItemClick(i);
            setRemoveAllSelection(widget.items[i]);
          },
        );
      },
    );
  }

  void setRemoveAllSelection(BarItem item) {
    setSafeState(() {
      for (BarItem tab in widget.items) {
        tab.isSelected = false;
        if (item._index == tab._index) {
          tab.isSelected = true;
        }
      }
    });
  }
}

class _BottomBarItemView extends StatefulWidget {
  const _BottomBarItemView({
    Key? key,
    required this.barItem,
    required this.removeAllSelect,
  }) : super(key: key);

  final BarItem barItem;
  final Function removeAllSelect;

  @override
  _BottomBarItemViewState createState() => _BottomBarItemViewState();
}

class _BottomBarItemViewState extends State<_BottomBarItemView>
    with TickerProviderStateMixin {
  List<_Point>? _points;
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          _animationController.reverse();
        }
      });
    super.initState();
  }

  void setAnimation() {
    _animationController.forward();
  }

  Widget _toBarIcon(final Color accentColor, final BarItem barItem) {
    if (barItem.isSelected) {
      return barItem.selectedIcon == null
          ? Image.asset(
              barItem.selectedIconPath!,
              width: barItem._size + 8.0,
              height: barItem._size + 8.0,
            )
          : Icon(
              barItem.selectedIcon,
              size: barItem._size + 8.0,
              color: Theme.of(context).secondary,
            );
    }
    return barItem.icon == null
        ? Image.asset(
            barItem.iconPath!,
            width: barItem._size,
            height: barItem._size,
          )
        : Icon(
            barItem.icon,
            size: barItem._size,
          );
  }

  @override
  Widget build(BuildContext context) {
    _points ??= _buildPoints();
    final ThemeData theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: RippleTap(
        onTap: () {
          if (!widget.barItem.isSelected) {
            setAnimation();
          }
          widget.removeAllSelect();
          widget.barItem.onClick?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: <Widget>[
              ScaleTransition(
                alignment: Alignment.center,
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(
                      0.1,
                      1.0,
                      curve: Curves.linear,
                    ),
                  ),
                ),
                child: _toBarIcon(theme.secondary, widget.barItem),
              ),
              ..._buildPointWidgets(theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPointWidgets(final ThemeData theme) {
    return List.generate(
      _points!.length,
      (index) => _buildPointWidget(_points![index], theme.secondary),
    );
  }

  Widget _buildPointWidget(final _Point point, final Color color) {
    return Positioned(
      top: point.top,
      bottom: point.bottom,
      left: point.left,
      right: point.right,
      child: ScaleTransition(
        alignment: Alignment.center,
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              point.interval[0],
              point.interval[1],
              curve: Curves.bounceInOut,
            ),
          ),
        ),
        child: Container(
          width: point.size,
          height: point.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  List<_Point> _buildPoints() {
    final random = math.Random();
    final int count = random.nextInt(2) + 3;
    final List<_Point> points = [];
    final double offset = 360 / count;
    final out = (offset / 4).floor();
    final always = offset - out;
    final Color color = Theme.of(context).secondary;
    color.withOpacity((random.nextDouble() + 0.1).clamp(0.1, 1.0));
    double angle;
    double size;
    double radius;
    double x;
    double y;
    List<double> interval;
    for (int i = 0; i < count; i++) {
      angle = offset * i + random.nextInt(out) + always;
      size = random.nextDouble() * 5 + 3;
      interval = [
        (random.nextDouble()).clamp(0, 0.7),
        (random.nextDouble()).clamp(0.8, 1)
      ];
      radius = (64 - 16) / 2;
      x = radius * math.cos(angle);
      y = radius * math.sin(angle);
      double? left;
      double? right;
      double? top;
      double? bottom;
      if (0 <= angle && 90 > angle) {
        right = radius - x.abs();
        top = radius - y.abs();
      } else if (90 <= angle && 180 > angle) {
        left = radius - x.abs();
        top = radius - y.abs();
      } else if (180 <= angle && 270 > angle) {
        left = radius - x.abs();
        bottom = radius - y.abs();
      } else {
        right = radius - x.abs();
        bottom = radius - y.abs();
      }
      points.add(_Point(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        size: size,
        interval: interval,
      ));
    }
    return points;
  }
}

class _Point {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final List<double> interval;
  final double size;

  _Point({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.interval,
    required this.size,
  });
}
