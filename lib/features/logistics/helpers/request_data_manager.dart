import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/image_utils/image_conversion_base_64_to_string.dart';

import '../../../data/local/database_helper.dart';
import '../../../data/repositories/standard_delivery/standard_delivery_repository.dart';
import '../../../data/repositories/image/image_repository.dart';
import '../../../data/services/messaging_controller.dart';
import '../../../data/repositories/app_data/cancel_remarks_repository.dart';
import '../controllers/web_socket_notification_controller.dart';
import '../models/notification_model.dart';
import '../models/standard_delivery_model.dart' as sd;
import '../models/cancel_remarks_model.dart';
import '../../personalization/controller/user_controller.dart';
import '../../../base/utils/constants/image_strings.dart';
import '../../../base/utils/constants/text_string.dart';
import '../../../base/utils/popups/full_screen_loader.dart';
import '../../../base/utils/popups/loaders.dart';
import '../../../base/utils/helpers/network_manager.dart';
import 'request_filter_manager.dart';
import 'request_form_state.dart';

class RequestDataManager {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final StandardDeliveryRepository _requestRepository =
      Get.find<StandardDeliveryRepository>();
  final CancelRemarksRepository _cancelRemarksRepository =
      Get.find<CancelRemarksRepository>();
  final MessagingController _messageController =
      Get.find<MessagingController>();
  final WebSocketNotificationController _webSocketController =
      Get.find<WebSocketNotificationController>();
  final UserController _userController = Get.find<UserController>();

  Future<bool> validateConnectivity() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      BLoaders.warningSnackBar(
        title: 'No Internet',
        message: 'Please check your internet connection.',
      );
      return false;
    }
    return true;
  }

  Future<void> saveRequest(RequestFormState formState) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) return;

    try {
      if (formState.requestedBy.text.isEmpty) {
        BLoaders.errorSnackBar(
            title: 'Request', message: 'Please select a requested by.');
        return;
      }

      if (formState.clientInformation.value!.id.isEmpty) {
        BLoaders.errorSnackBar(
            title: 'Client', message: 'Please select a Client.');
        return;
      }

      final documentReferences =
          formState.documentReferenceControllers.map((c) => c.text).toList();

      if (documentReferences.isEmpty ||
          documentReferences.any((ref) => ref.isEmpty)) {
        BLoaders.errorSnackBar(
            title: 'Document Reference',
            message: 'Please enter at least one document reference.');
        return;
      }

      final newRequest = sd.StandardDeliveryModel.fromFormInputs(
        clientId: formState.clientInformation.value?.id,
        shippingMethod: formState.shippingMethod.text,
        deliveryTerms: formState.deliveryTerms.text,
        deliveryDate: formState.targetDate.text,
        requestBy: formState.requestedBy.text,
        documentReference: documentReferences,
        preference: formState.preference.text,
        client: formState.clientInformation.value,
        createdBy: _userController.user.value.initial,
      );

      _webSocketController.sendNotificationMessage(
        NotificationModel(title: 'New', body: 'New Request Received!'),
      );
      final managersPhoneNumber = await _dbHelper
          .getUserAndManagerPhoneNumbers(formState.requestedBy.text);

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (newRequest.createdBy == 'MEO') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('LNA'));
      }

      if (newRequest.createdBy == 'AVS') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('RPT'));
      }

      if (newRequest.createdBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, BTexts.statusNewRequest, newRequest);

      // use domain repository
      await _requestRepository.insertDelivery(newRequest);
      formState.reset();
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: "An error occurred: ${e.toString()}");
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  Future<void> updateRequestStatus(
      sd.StandardDeliveryModel requestModel,
      String newStatus,
      String userInitial,
      RequestFormState formState,
      Rx<sd.StandardDeliveryModel?> currentSelectedRequest,
      bool useLocalStorage) async {
    try {
      final nowString = DateTime.now().toString();

      // Resolve mobileID safely (the form stores text, DB/model uses int?)
      int? resolvedMobileID;
      if (newStatus == BTexts.statusItemPrepared) {
        // if model has no mobile assigned or is zero, try to parse from form input
        if (requestModel.mobileID == null || requestModel.mobileID == 0) {
          resolvedMobileID =
              int.tryParse(formState.mobile.text) ?? requestModel.mobileID;
        } else {
          resolvedMobileID = requestModel.mobileID;
        }
      } else {
        resolvedMobileID = requestModel.mobileID;
      }

      String finalImageBase64 = requestModel.image;
      if (newStatus == BTexts.statusDoneDelivery &&
          requestModel.image.isEmpty) {
        finalImageBase64 = await BImageHelperFunctions.getDeliveryImageAsBase64(
                newStatus, requestModel) ??
            formState.cameraPickUpPicture.value;
      }

      final updatedRequest = requestModel.copyWith(
        status: newStatus,
        itemPreparedBy: newStatus == BTexts.statusGettingSuppliesReady &&
                requestModel.itemPreparedBy.isEmpty
            ? userInitial
            : requestModel.itemPreparedBy,
        deliveredBy: newStatus == BTexts.statusItemPrepared &&
                requestModel.deliveredBy.isEmpty
            ? formState.selectedDriver.text
            : requestModel.deliveredBy,
        itemPreparedAt: newStatus == BTexts.statusGettingSuppliesReady &&
                requestModel.itemPreparedAt.isEmpty
            ? nowString
            : requestModel.itemPreparedAt,
        itemPreparedEndAt: newStatus == BTexts.statusItemPrepared &&
                requestModel.itemPreparedEndAt.isEmpty
            ? nowString
            : requestModel.itemPreparedEndAt,
        deliveredAt: newStatus == BTexts.statusForDelivery &&
                requestModel.deliveredAt.isEmpty
            ? nowString
            : requestModel.deliveredAt,
        deliveredEndAt: newStatus == BTexts.statusDoneDelivery &&
                requestModel.deliveredEndAt.isEmpty
            ? nowString
            : requestModel.deliveredEndAt,
        locationStartedAt: newStatus == BTexts.statusForDelivery &&
                requestModel.locationStartedAt.isEmpty
            ? nowString
            : requestModel.locationStartedAt,
        locationEndAt: newStatus == BTexts.statusDoneDelivery &&
                requestModel.locationEndAt.isEmpty
            ? nowString
            : requestModel.locationEndAt,
        helper: newStatus == BTexts.statusItemPrepared &&
                requestModel.helper.isEmpty
            ? formState.selectedHelper.text
            : requestModel.helper,
        receiver: newStatus == BTexts.statusDoneDelivery &&
                requestModel.receiver.isEmpty
            ? formState.receiver.text
            : requestModel.receiver,
        mobileID: resolvedMobileID,
        tripTicketNumber: newStatus == BTexts.statusItemPrepared &&
                requestModel.tripTicketNumber.isEmpty
            ? formState.tripTicketNumber.text
            : requestModel.tripTicketNumber,
      );

      final bool signatureWasAdded = newStatus == BTexts.statusDoneDelivery &&
          requestModel.signature.isEmpty &&
          formState.receiverSignatureBase64.value.isNotEmpty;

      if (signatureWasAdded) {
        // Try uploading signature if online. If upload fails, continue but notify user.
        final isConnectedForUpload =
            await NetworkManager.instance.isConnected();
        if (isConnectedForUpload) {
          // call repository upload (non-blocking for DB update but await to propagate errors)
          await ImageRepository.instance.uploadFile(
            requestId: updatedRequest.id.isNotEmpty
                ? updatedRequest.id
                : requestModel.id,
            base64Image: formState.receiverSignatureBase64.string,
            type: 'Signature',
          );
        } else {
          BLoaders.warningSnackBar(
              title: 'No Internet',
              message:
                  'Signature saved locally. It will be uploaded when internet connection is available.');
        }
      }

      // Upload image proof when a delivery image was just added (type: 'Proof').
      final bool imageProofWasAdded = newStatus == BTexts.statusDoneDelivery &&
          requestModel.image.isEmpty &&
          finalImageBase64.isNotEmpty;

      if (imageProofWasAdded) {
        final isConnectedForUpload =
            await NetworkManager.instance.isConnected();
        if (isConnectedForUpload) {
          try {
            await ImageRepository.instance.uploadFile(
              requestId: updatedRequest.id.isNotEmpty
                  ? updatedRequest.id
                  : requestModel.id,
              base64Image: finalImageBase64,
              type: 'Proof',
            );
          } catch (e) {
            // Non-fatal: notify user that upload failed and will be retried later
            BLoaders.warningSnackBar(
              title: 'Upload Failed',
              message:
                  'Image proof could not be uploaded. It will be synced when connection is available.',
            );
          }
        } else {
          BLoaders.warningSnackBar(
              title: 'No Internet',
              message:
                  'Image saved locally. It will be uploaded when internet connection is available.');
        }
      }

      if (!useLocalStorage) {
        await _dbHelper.updateRequest(requestModel: updatedRequest);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _requestRepository.updateDelivery(updatedRequest);
          await _dbHelper.updateRequest(requestModel: updatedRequest);
        } else {
          await _dbHelper.updateRequest(requestModel: updatedRequest);
          BLoaders.warningSnackBar(
            title: 'No Internet',
            message:
                'Request updated locally. Sync with server when connection returns.',
          );
        }
      }

      // Local-only save
      await _dbHelper.updateRequest(requestModel: updatedRequest);
      // Persist any media captured (signature/image) locally
      await _dbHelper.saveRequestMedia(
        requestID: updatedRequest.id.isNotEmpty
            ? updatedRequest.id
            : updatedRequest.requestID,
        signature: formState.receiverSignatureBase64.value.isNotEmpty
            ? formState.receiverSignatureBase64.value
            : null,
        image: finalImageBase64.isNotEmpty ? finalImageBase64 : null,
      );

      _webSocketController.sendNotificationMessage(
        NotificationModel(title: 'Update', body: updatedRequest.status),
      );

      final managersPhoneNumber = await _dbHelper
          .getUserAndManagerPhoneNumbers(updatedRequest.requestBy);

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (newStatus == BTexts.statusItemPrepared &&
          requestModel.itemPreparedBy == 'LNA') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('MEO'));
      }

      if (newStatus == BTexts.statusItemPrepared &&
          requestModel.itemPreparedBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, newStatus, updatedRequest);

      currentSelectedRequest.value = updatedRequest;

      formState.reset();
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Update Failed',
          message: "An error occurred: ${e.toString()}");
    } finally {
      if (newStatus != BTexts.statusForDelivery) {
        BFullScreenLoader.stopLoading();
      }
    }
  }

  Future<void> fetchPendingRequestsAPI(
      RxList<sd.StandardDeliveryModel> allPendingRequests,
      RequestFilterManager filterManager) async {
    if (!await validateConnectivity()) {
      return;
    }

    try {
      final apiRequests = await _requestRepository.getAllPending();

      allPendingRequests.assignAll(apiRequests);

      await _dbHelper.insertRequests(apiRequests);

      filterManager.applyFilter(allPendingRequests.toList());
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'API Fetch Failed',
          message: "Could not load requests from API: ${e.toString()}");
    }
  }

  Future<void> loadDataFromSqfLite(
      RxList<sd.StandardDeliveryModel> allPendingRequests,
      RequestFilterManager filterManager) async {
    try {
      final requestsFromDb = await _dbHelper.getRequests();
      if (requestsFromDb.isEmpty) {
        await fetchPendingRequestsAPI(allPendingRequests, filterManager);
      } else {
        allPendingRequests.assignAll(requestsFromDb);

        filterManager.applyFilter(allPendingRequests.toList());
      }
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Fetch Failed',
          message: "Could not load requests: ${e.toString()}");
    }
  }

  Future<void> uploadModifiedRequest() async {
    try {
      final requests = await _dbHelper.getRequests();
      for (var request in requests) {
        if (request.status != BTexts.statusNewRequest) {
          await _requestRepository.updateDelivery(request);
        }
      }
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Fetch Failed',
          message: "Could not load requests: ${e.toString()}");
    }
  }

  Future<void> cancelRequestWithRemarks(sd.StandardDeliveryModel requestModel,
      String remarks, bool userLocalStorage) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) {
      // No connectivity: stop loader and inform the user, then return.
      BFullScreenLoader.stopLoading();
      BLoaders.warningSnackBar(
        title: 'No Internet',
        message:
            'Request updated locally. Sync with server when connection returns.',
      );
      return;
    }

    try {
      if (!userLocalStorage) {
        await _dbHelper.cancelRequestWithRemarks(
            requestID: requestModel.id,
            remarks: remarks,
            newStatus: BTexts.statusCancelled);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _requestRepository.cancelDelivery(requestModel.id, remarks);
          await _dbHelper.cancelRequestWithRemarks(
              requestID: requestModel.id,
              remarks: remarks,
              newStatus: BTexts.statusCancelled);
        } else {
          await _dbHelper.cancelRequestWithRemarks(
              requestID: requestModel.id,
              remarks: remarks,
              newStatus: BTexts.statusCancelled);
          BLoaders.warningSnackBar(
            title: 'No Internet',
            message:
                'Request updated locally. Sync with server when connection returns.',
          );
        }
      }

      _webSocketController.sendNotificationMessage(
        NotificationModel(
            title: 'Request Cancelled!', body: 'Reason: $remarks'),
      );

      List<String> managersPhoneNumber = [];

      managersPhoneNumber
          .add(await _dbHelper.getUserPhoneNumberByUsername('RLD'));

      if (requestModel.itemPreparedBy == 'LNA') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('MEO'));
      }

      if (requestModel.itemPreparedBy == 'RPT') {
        managersPhoneNumber
            .add(await _dbHelper.getUserPhoneNumberByUsername('AVS'));
      }

      await _messageController.sendSmsMessage(
          managersPhoneNumber, BTexts.statusCancelled, requestModel);
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: "An error occurred: ${e.toString()}");
    } finally {
      // Ensure the full-screen loader is stopped on all paths.
      BFullScreenLoader.stopLoading();
    }
  }

  /// Fetch cancel remarks for a request. Prefers local DB, falls back to API.
  /// Persists API results to local DB when available.
  Future<CancelRemarksModel> fetchCancelRemarks(String requestId) async {
    try {
      // Try local DB first
      try {
        final bool exists = await _dbHelper.isRequestRemarkExisting(requestId);
        if (exists) {
          return await _dbHelper.getRequestRemarks(requestId);
        }
      } catch (_) {
        // ignore local DB read failures
      }

      // Fallback to API
      try {
        final apiResult = await _cancelRemarksRepository
            .getCancelRemarksByRequestId(requestId);
        if (apiResult != CancelRemarksModel.empty) {
          // persist to local DB
          try {
            final remarksDao = await _dbHelper.remarksDao;
            await remarksDao.insertRemark(
                requestId, apiResult.remarks, apiResult.date);
          } catch (_) {
            // ignore persistence errors
          }
          return apiResult;
        }
        return CancelRemarksModel.empty;
      } catch (_) {
        return CancelRemarksModel.empty;
      }
    } catch (_) {
      return CancelRemarksModel.empty;
    }
  }
}
