
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/image_utils/image_conversion_base_64_to_string.dart';

import '../../../data/local/database_helper.dart';
import '../../../data/repositories/request/request_repository.dart';
import '../../../data/services/messaging_controller.dart';
import '../controllers/web_socket_notification_controller.dart';
import '../models/notification_model.dart';
import '../models/request_model.dart';
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
  final RequestRepository _requestRepository = Get.find<RequestRepository>();
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

      final newRequest = RequestModel.fromFormInputs(
        clientId: formState.clientInformation.value?.id,
        shippingMethod: formState.shippingMethod.text,
        deliveryTerms: formState.deliveryTerms.text,
        targetDate: formState.targetDate.text,
        requestedBy: formState.requestedBy.text,
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

      await _requestRepository.insertRequest(newRequest);
      formState.reset();
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Save Failed', message: "An error occurred: ${e.toString()}");
    } finally {
      BFullScreenLoader.stopLoading();
    }
  }

  Future<void> updateRequestStatus(
      RequestModel requestModel,
      String newStatus,
      String userInitial,
      RequestFormState formState,
      Rx<RequestModel?> currentSelectedRequest,
      bool useLocalStorage) async {
    try {
      final nowString = DateTime.now().toString();

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
        signature: newStatus == BTexts.statusDoneDelivery &&
                requestModel.signature.isEmpty
            ? formState.receiverSignatureBase64.value
            : requestModel.signature,
        mobileID: newStatus == BTexts.statusItemPrepared &&
                (requestModel.mobileID == '0' || requestModel.mobileID.isEmpty)
            ? formState.mobile.text
            : requestModel.mobileID,
        image:
            newStatus == BTexts.statusDoneDelivery && requestModel.image.isEmpty
                ? await BImageHelperFunctions.getDeliveryImageAsBase64(
                        newStatus, requestModel) ??
                    formState.cameraPickUpPicture.value
                : requestModel.image,
        tripTicketNumber: newStatus == BTexts.statusItemPrepared &&
                requestModel.tripTicketNumber.isEmpty
            ? formState.tripTicketNumber.text
            : requestModel.tripTicketNumber,
      );

      /// YOU ARE HERE
      if (!useLocalStorage) {
        await _dbHelper.updateRequest(requestModel: updatedRequest);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _requestRepository.updateRequest(updatedRequest);
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

      _webSocketController.sendNotificationMessage(
        NotificationModel(title: 'Update', body: updatedRequest.status),
      );

      final managersPhoneNumber = await _dbHelper
          .getUserAndManagerPhoneNumbers(updatedRequest.requestedBy);

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

  Future<void> fetchPendingRequestsAPI(RxList<RequestModel> allPendingRequests,
      RequestFilterManager filterManager) async {
    if (!await validateConnectivity()) {
      return;
    }

    try {
      final apiRequests = await _requestRepository.getAllPendingRequestAPI();
      allPendingRequests.assignAll(apiRequests);

      await _dbHelper.insertRequests(apiRequests);

      filterManager.applyFilter(allPendingRequests);
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'API Fetch Failed',
          message: "Could not load requests from API: ${e.toString()}");
    }
  }

  Future<void> loadDataFromSqfLite(RxList<RequestModel> allPendingRequests,
      RequestFilterManager filterManager) async {
    try {
      final requestsFromDb = await _dbHelper.getRequests();
      if (requestsFromDb.isEmpty) {
        await fetchPendingRequestsAPI(allPendingRequests, filterManager);
      } else {
        allPendingRequests.assignAll(requestsFromDb);

        filterManager.applyFilter(allPendingRequests);
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
          await _requestRepository.updateRequest(request);
        }
      }
    } catch (e) {
      BLoaders.errorSnackBar(
          title: 'Fetch Failed',
          message: "Could not load requests: ${e.toString()}");
    }
  }

  Future<void> cancelRequestWithRemarks(
      RequestModel requestModel, String remarks, bool userLocalStorage) async {
    BFullScreenLoader.openLoadingDialog(
        'Saving on process...', BImages.docerAnimation);

    if (!await validateConnectivity()) return;

    try {
      if (!userLocalStorage) {
        _dbHelper.cancelRequestWithRemarks(
            requestID: requestModel.requestID,
            remarks: remarks,
            newStatus: BTexts.statusCancelled);
      } else {
        final isConnected = await validateConnectivity();
        if (isConnected) {
          await _requestRepository.cancelRequest(
              requestModel.requestID, remarks);
          _dbHelper.cancelRequestWithRemarks(
              requestID: requestModel.requestID,
              remarks: remarks,
              newStatus: BTexts.statusCancelled);
        } else {
          _dbHelper.cancelRequestWithRemarks(
              requestID: requestModel.requestID,
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
    }
  }
}
