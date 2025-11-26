import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/status_action_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_request_modal_footer.dart';

class PullOutModal extends StatelessWidget {
  final PullOutModel requestModel;
  final VoidCallback onPressed;
  final bool isActionVisible;

  const PullOutModal({
    super.key,
    required this.requestModel,
    required this.onPressed,
    this.isActionVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return RequestModalScaffold(
      header: PullOutRequestModalHeader(requestModel: requestModel),
      documentReferences: requestModel.documentReference,
      bottomAction: StatusActionButton(
        status: requestModel.requestStatus,
        onPressed: onPressed,
        isVisible: isActionVisible,
        statusToTextMapper: (status) {
          if (status == null) return 'Proceed';
          switch (status) {
            case 'New Request':
              return 'Set In Transit';
            case 'In Transit':
              return 'Mark Taken Out';
            case 'Taken Out':
              return '';
            default:
              return 'Proceed';
          }
        },
      ),
      children: [
        PullOutRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
