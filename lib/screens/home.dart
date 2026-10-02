import 'package:flutter/material.dart';
import 'package:json_to_dart/controllers/converter_controller.dart';
import 'package:json_to_dart/util/web_utils.dart';
import 'package:json_to_dart/widgets/app_footer.dart';
import 'package:json_to_dart/widgets/app_header.dart';
import 'package:json_to_dart/widgets/input_panel.dart';
import 'package:json_to_dart/widgets/output_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _wideLayoutMinWidth = 800;

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
      body: Column(
        children: [
          const AppHeader(),
          const Divider(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final List<Widget> panels = [
                      Expanded(child: InputPanel(controller: _controller)),
                      Expanded(child: OutputPanel(controller: _controller)),
                    ];
                    return constraints.maxWidth >= _wideLayoutMinWidth
                        ? Row(children: panels)
                        : Column(children: panels);
                  },
                ),
              ),
            ),
          ),
          const Divider(),
          const AppFooter(),
        ],
      ),
    );
  }
}
