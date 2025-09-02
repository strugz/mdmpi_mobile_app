import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../base/utils/popups/full_screen_loader.dart';
import '../../../controllers/request_controller.dart';

class BRequestTransportHelper extends StatelessWidget {
  const BRequestTransportHelper(
      {super.key,
      required this.requestController});

  final RequestController requestController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: requestController.formState.selectedHelper,
      onTap: () {
        BFullScreenLoader.showUserChecklistItem(
          context: context,
          currentSelectionController: requestController.formState.selectedHelper,
          dialogTitle: 'Driver',
        );
      },
      decoration: const InputDecoration(
        // Added const
        prefixIcon: Icon(Iconsax.user_add),
        labelText: 'Driver',
      ),
    );
  }
}
