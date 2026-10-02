import 'package:flutter/material.dart';
import 'package:json_to_dart/util/constants.dart';
import 'package:json_to_dart/util/web_utils.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "Open developer profile",
      child: InkWell(
        onTap: () => WebUtils.openUrl(Constant.developerUrl),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            "Developed & maintained by ${Constant.developerName}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
