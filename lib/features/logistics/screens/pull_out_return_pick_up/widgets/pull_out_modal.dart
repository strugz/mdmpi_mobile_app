import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/modals/request_modal_scaffold.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/pull_out_modal_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/widgets/b_pull_out_action_button.dart';
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
      bottomAction: BPullOutActionButton(
        status: requestModel.requestStatus,
        onPressed: onPressed,
        isVisible: isActionVisible,
      ),
      children: [
        PullOutRequestModalFooter(requestModel: requestModel),
      ],
    );
  }
}
