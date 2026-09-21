import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/dashboard_view.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_quick_actions.dart';

/// Logistics Home: the brand header with the "New request" grid first, then
/// the activity dashboard filling the rest of the screen.
///
/// One screen, no scrolling. The body is laid out in a `SliverFillRemaining`
/// with no scroll body, which sizes its child to the viewport, or to the
/// child's own minimum height when the screen is too short. So on a tall
/// phone everything stretches to fit; on a short one the page scrolls instead
/// of overflowing. That requires every widget in the column to report an
/// intrinsic height, hence no `GridView` or `LayoutBuilder` on this screen.
///
/// Pull down to refresh; the header also carries a refresh button. The nav
/// shell already pads for the system bottom inset.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? BColors.black : BColors.lightGrey,
      body: RefreshIndicator.adaptive(
        color: BColors.primary,
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: controller.refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LogisticsHomeHeader(
                    quickActions: HomeQuickActionGrid(
                      labels: BTexts.requestFormLabels,
                      pages: AppRoutes.requestFormPages,
                      iconPaths: BImages.requestFormIconPaths,
                    ),
                  ),

                  /// Dashboard. The top strip behind the hero card is painted
                  /// in the brand colour so the card overlaps the header.
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: LogisticsHomeHeader.overlap,
                          child: ColoredBox(color: BColors.primary),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            BSizes.defaultSpace,
                            0,
                            BSizes.defaultSpace,
                            BSizes.sm + BSizes.xs,
                          ),
                          child: DashboardView(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
