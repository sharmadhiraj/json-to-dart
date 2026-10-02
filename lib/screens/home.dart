import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/widgets/app_footer.dart';
import 'package:json_to_dart/widgets/app_header.dart';
import 'package:json_to_dart/widgets/input_panel.dart';
import 'package:json_to_dart/widgets/options_bar.dart';
import 'package:json_to_dart/widgets/output_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onToggleTheme, super.key});

  final ValueChanged<Brightness> onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideLayoutMinWidth = 800;
  static const double _wideLayoutMinHeight = 640;
  static const double _maxContentWidth = 1200;
  static const double _narrowPanelHeight = 460;

  final ConverterController _controller = ConverterController();
  late final void Function() _removeDropListener;

  @override
  void initState() {
    super.initState();
    _controller.load();
    _removeDropListener = WebUtils.onFileDropped(_controller.setJson);
  }

  @override
  void dispose() {
    _removeDropListener();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth >= _wideLayoutMinWidth;
          final Widget page = Column(
            children: [
              AppHeader(onToggleTheme: widget.onToggleTheme),
              const Divider(height: 1),
              if (wide) Expanded(child: _buildMain(wide)) else _buildMain(wide),
              const Divider(height: 1),
              const AppFooter(),
            ],
          );
          return SingleChildScrollView(
            child: wide
                ? SizedBox(
                    height: max(constraints.maxHeight, _wideLayoutMinHeight),
                    child: page,
                  )
                : page,
          );
        },
      ),
    );
  }

  Widget _buildMain(bool wide) {
    final Widget input = InputPanel(controller: _controller);
    final Widget output = OutputPanel(controller: _controller);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
            children: [
              OptionsBar(controller: _controller, wide: wide),
              const SizedBox(height: 16),
              if (wide)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: input),
                      const SizedBox(width: 16),
                      Expanded(child: output),
                    ],
                  ),
                )
              else ...[
                SizedBox(height: _narrowPanelHeight, child: input),
                const SizedBox(height: 16),
                SizedBox(height: _narrowPanelHeight, child: output),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
