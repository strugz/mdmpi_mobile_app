import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'b_cancel_remarks.dart';

/// Widget that loads cancel remarks for a given request and displays
/// the [BCancelRemarks] widget. It prefers controller/local DB cache and
/// falls back to the request model when no data is available.
class BCancelRemarksLoader extends StatefulWidget {
  final StandardDeliveryModel requestModel;

  const BCancelRemarksLoader({Key? key, required this.requestModel}) : super(key: key);

  @override
  State<BCancelRemarksLoader> createState() => _BCancelRemarksLoaderState();
}

class _BCancelRemarksLoaderState extends State<BCancelRemarksLoader> {
  late final StandardDeliveryController _ctrl;
  late final String _requestId;

  @override
  void initState() {
    super.initState();
    _ctrl = StandardDeliveryController.instance;
    _requestId = widget.requestModel.id.isNotEmpty ? widget.requestModel.id : widget.requestModel.requestID;

    // Trigger fetch once (controller has guards to prevent duplicate fetches)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alreadyLoaded = _ctrl.cancelRemarksCache.containsKey(_requestId);
      final isLoading = _ctrl.cancelRemarksLoading[_requestId] == true;
      if (!alreadyLoaded && !isLoading) {
        _ctrl.fetchCancelRemarks(_requestId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = _ctrl.cancelRemarksLoading[_requestId] == true;
      if (loading) {
        return const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final data = _ctrl.cancelRemarksCache[_requestId] ?? CancelRemarksModel.empty;
      if (data == CancelRemarksModel.empty) {
        return BCancelRemarks(
          remarks: widget.requestModel.cancelRemarks.remarks,
          date: widget.requestModel.cancelRemarks.date,
        );
      }

      return BCancelRemarks(
        remarks: data.remarks.isNotEmpty ? data.remarks : widget.requestModel.cancelRemarks.remarks,
        date: data.date.isNotEmpty ? data.date : widget.requestModel.cancelRemarks.date,
      );
    });
  }
}

