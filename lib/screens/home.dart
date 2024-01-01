import 'package:flutter/material.dart';
import 'package:json_to_dart/util/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(Constant.appName),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Container();
  }
}
