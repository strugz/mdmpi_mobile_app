import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';

class PullOutForm extends StatelessWidget {
  const PullOutForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(title: const Text("Pull Out Form"), showBackArrow: true),
    );
  }
}
