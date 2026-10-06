import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_account_information_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The Reconciliation list. Its "Details" link was wired to an empty
/// callback, so pressing it did nothing; it opens the account's page, as
/// Details does from the bucket.

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

final _amka = ClientModel(
  id: 'NCR-1',
  code: 'NCR-1',
  name: 'Amka Trading',
  address: '',
  contact: '',
  emailAddress: '',
);

void main() {
  tearDown(Get.reset);

  testWidgets('Details opens the account page', (tester) async {
    final activity = _Activity();
    Get.put<CollectionActivityController>(activity);
    activity.masterAccountList.assignAll([_amka]);
    activity.bucketItems.assignAll([
      CollectionItemModel(
        id: '700009771',
        client: _amka,
        toBeCollected: 21048.87,
        status: 'Reconciliation',
      ),
    ]);

    await tester.pumpWidget(GetMaterialApp(
      theme: BCollectionTheme.light,
      home: const CategoryDetailScreen(
          title: 'Reconciliation', color: BCollectionColors.warning),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Amka Trading'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.byType(CollectionAccountInformationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
