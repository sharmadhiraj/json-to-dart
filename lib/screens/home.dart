import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/data/app_settings.dart';
import 'package:json_to_dart/data/share_codec.dart';
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
    final AppSettings? shared = ShareCodec.fromUri(Uri.base);
    _controller.load(initial: shared);
    if (shared != null) {
      WebUtils.replaceUrl(ShareCodec.withoutShare(Uri.base).toString());
    }
    _removeDropListener = WebUtils.onFileDropped(_controller.setJson);
  }

  @override
  void dispose() {
    _removeDropListener();
    _controller.dispose();
    super.dispose();
  }

  void _download() {
    if (_controller.dartClass.isEmpty) return;
    WebUtils.downloadFile(_controller.fileName, _controller.dartClass);
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts {
    final Map<LogicalKeyboardKey, VoidCallback> plain = {
      LogicalKeyboardKey.enter: _controller.copyOutput,
      LogicalKeyboardKey.keyS: _download,
    };
    return {
      for (final MapEntry<LogicalKeyboardKey, VoidCallback> e
          in plain.entries) ...{
        SingleActivator(e.key, control: true): e.value,
        SingleActivator(e.key, meta: true): e.value,
      },
      const SingleActivator(
        LogicalKeyboardKey.keyF,
        control: true,
        shift: true,
      ): _controller.formatJson,
      const SingleActivator(
        LogicalKeyboardKey.keyF,
        meta: true,
        shift: true,
      ): _controller.formatJson,
    };
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Scaffold(
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
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
