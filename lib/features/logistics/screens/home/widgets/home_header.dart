import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/dashboard_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

/// The Home header on the brand colour: greeting and date, the user's name, a
/// refresh button, and the "New request" tile grid so filing a request is the
/// first thing on the screen.
///
/// The dashboard card below overlaps this block's lower edge by [overlap];
/// the Home screen paints that strip in the brand colour behind the card.
class LogisticsHomeHeader extends StatelessWidget {
  const LogisticsHomeHeader({
    super.key,
    required this.quickActions,
    this.now,
  });

  /// The "New request" grid rendered inside the header.
  final Widget quickActions;

  /// Injected for tests; defaults to the wall clock.
  final DateTime? now;

  /// How far the card below reaches up into this header's colour.
  static const double overlap = 40;

  static const String newRequestTitle = 'New request';

  static String greetingFor(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final time = now ?? DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final muted = BColors.white.withValues(alpha: 0.75);

    return Container(
      width: double.infinity,
      color: BColors.primary,
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        topInset + BSizes.sm + BSizes.xs,
        BSizes.defaultSpace,
        BSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${greetingFor(time)} · '
                      '${DateFormat('EEEE, d MMMM').format(time)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium!.apply(color: muted),
                    ),
                    const SizedBox(height: BSizes.xxs),
                    _UserName(textTheme: textTheme),
                  ],
                ),
              ),
              const SizedBox(width: BSizes.sm),
              const _RefreshButton(),
            ],
          ),
          const SizedBox(height: BSizes.md),
          Text(
            newRequestTitle,
            style: textTheme.labelMedium!.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: BSizes.sm),
          quickActions,
        ],
      ),
    );
  }
}

class _UserName extends StatelessWidget {
  const _UserName({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<UserController>()
        ? Get.find<UserController>()
        : null;
    final style = textTheme.titleLarge!.copyWith(
      color: BColors.white,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    if (controller == null) return Text(' ', style: style);

    return Obx(() {
      if (controller.profileLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.xxs),
          child: BShimmerEffect(width: 140, height: 20, radius: 6),
        );
      }
      return Text(
        controller.user.value.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    });
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    if (controller == null) return const SizedBox.shrink();

    return Obx(() {
      final busy = controller.isRefreshing.value;
      return IconButton(
        tooltip: 'Refresh',
        onPressed: busy ? null : controller.refreshDashboard,
        style: IconButton.styleFrom(
          backgroundColor: BColors.white.withValues(alpha: 0.15),
          foregroundColor: BColors.white,
          disabledBackgroundColor: BColors.white.withValues(alpha: 0.15),
          disabledForegroundColor: BColors.white.withValues(alpha: 0.6),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BColors.white,
                ),
              )
            : const Icon(Iconsax.refresh, size: 20),
      );
    });
  }
}
