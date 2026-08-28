import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_request_form.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_view.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';

import '../../../../base/utils/constants/image_strings.dart';

/// Home screen displaying request form shortcuts and activity dashboard.
///
/// Architecture:
/// - DashboardView + DashboardController aggregate all six request modules
///   with module and year/month filters
/// - Pure UI layer - no data logic in build methods
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header
            const BPrimaryHeaderContainer(
              child: Column(
                children: [
                  BHomeAppBar(),
                  SizedBox(height: BSizes.spaceBtwSections),
                ],
              ),
            ),

            /// Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              child: Column(
                children: [
                  const BSectionHeading(
                    title: BTexts.homeSubTitle3,
                    showActionButton: false,
                  ),

                  /// Request Form Shortcuts
                  BRequestForm(
                    labels: BTexts.requestFormLabels,
                    pages: AppRoutes.requestFormPages,
                    iconPaths: BImages.requestFormIconPaths,
                  ),

                  const SizedBox(height: BSizes.spaceBtwItemsLight),

                  /// Activity Dashboard (all modules, filterable)
                  const DashboardView(),

                  // Extra space at the bottom to ensure visibility on all devices
                  const SizedBox(height: BSizes.spaceBtwSections * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
