import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';

class PickUpForm extends StatelessWidget {
  const PickUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(title: const Text("Pick Up Form"), showBackArrow: true),
    );
  }
}
