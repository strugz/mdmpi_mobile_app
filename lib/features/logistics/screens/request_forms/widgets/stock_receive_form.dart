import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';

class StockReceiveForm extends StatelessWidget {
  const StockReceiveForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(title: const Text("Stock Receive Form"), showBackArrow: true),
    );
  }
}
