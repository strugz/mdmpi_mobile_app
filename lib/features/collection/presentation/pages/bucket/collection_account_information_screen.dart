import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class CollectionAccountInformationScreen extends StatelessWidget {
  final ClientModel client;

  const CollectionAccountInformationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${client.name} Info'),
      ),
      body: const Center(
        child: Text('Account Information Placeholder'),
      ),
    );
  }
}
