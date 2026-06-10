import 'package:flutter/material.dart';
import '../widgets/sidebar/sidebar_panel.dart';
import '../widgets/detail/detail_panel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _sidebarWidth = 280;
  static const double _minSidebarWidth = 180;
  static const double _maxSidebarWidth = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: _sidebarWidth,
            child: const SidebarPanel(),
          ),
          _ResizeDivider(
            onDrag: (delta) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + delta)
                    .clamp(_minSidebarWidth, _maxSidebarWidth);
              });
            },
          ),
          const Expanded(child: DetailPanel()),
        ],
      ),
    );
  }
}

class _ResizeDivider extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _ResizeDivider({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: 5,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
