import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

import '../../base/utils/helpers/network_manager.dart';
import '../local/database_helper.dart';

class ClientController extends GetxController {
  static ClientController get instance => Get.find();

  /// Variables
  final isLoading = false.obs;
  final _clientRepository = Get.find<ClientRepository>();
  final query = TextEditingController();
  RxList<ClientModel> allClient = <ClientModel>[].obs;
  RxList<ClientModel> searchClient = <ClientModel>[].obs;

  Future<void> fetchClientFromDb(bool isDisplay) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      //  Show loader while loading categories
      isLoading.value = true;
      var loadedData = false;

      final checkClient = await dbHelper.hasACCMSTData();

      if (checkClient) {
        final localClients = await dbHelper.searchClients('');
        allClient.assignAll(localClients);
        searchClient.assignAll(localClients);
        loadedData = true;
      } else if (await NetworkManager.instance.isConnected()) {
        List<ClientModel> apiClients =
            await _clientRepository.getAllClientAPI();
        if (apiClients.isNotEmpty) {
          await dbHelper.insertClients(apiClients);
          allClient.assignAll(apiClients);
          searchClient.assignAll(apiClients);
          loadedData = true;
        } else {
          BLoaders.errorSnackBar(
              title: 'Oh Snap!', message: 'No clients fetched from API.');
        }
      }
      if (isDisplay == true && loadedData) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'Client List Updated');
      }
    } catch (e) {
      logDebug('ClientController.fetchClientFromDb failed: $e');
    } finally {
      //  Remove Loader
      isLoading.value = false;
    }
  }

  Future<void> fetchClientFromServer(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.warningSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }
    try {
      final dbHelper = DatabaseHelper.instance;

      isLoading.value = true;

      List<ClientModel> apiClients = await _clientRepository.getAllClientAPI();
      if (apiClients.isNotEmpty) {
        await dbHelper.insertClients(apiClients);
      } else {
        BLoaders.errorSnackBar(
            title: 'Oh Snap!', message: 'No clients fetched from API.');
      }

      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'Client List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      //  Remove Loader
      isLoading.value = false;
    }
  }

  Future<void> hardResetClients(bool isDisplay) async {
    final isConnected = await NetworkManager.instance.isConnected();

    if (!isConnected) {
      BLoaders.warningSnackBar(
          title: "Internet", message: "No Internet Connection");
      return;
    }

    try {
      final dbHelper = DatabaseHelper.instance;
      isLoading.value = true;

      final apiClients = await _clientRepository.getAllClientAPI();

      await dbHelper.deleteClients();
      if (apiClients.isNotEmpty) {
        await dbHelper.insertClients(apiClients);
      }

      allClient.assignAll(apiClients);
      searchClient.assignAll(apiClients);

      if (isDisplay == true) {
        BLoaders.successSnackBar(
            title: 'Success', message: 'Client List Updated');
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterClientFromDb(String searchQuery) async {
    try {
      isLoading.value = true;
      searchClient.clear();
      if (searchQuery.isEmpty) {
        final dbHelper = DatabaseHelper.instance;
        final allClientsFromDb =
            await dbHelper.searchClients(''); // Pass empty string to get all
        searchClient.assignAll(allClientsFromDb);
      } else {
        final dbHelper = DatabaseHelper.instance;
        final filteredClientsFromDb = await dbHelper.searchClients(searchQuery);
        searchClient.assignAll(filteredClientsFromDb.where((client) =>
            client.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            client.code.toLowerCase().contains(searchQuery.toLowerCase())));
      }
    } catch (e) {
      BLoaders.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
