import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/shimmer.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_circular_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/section_heading.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/widgets/change_name.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/profile/widgets/profile_menu.dart';

import '../../../../base/utils/constants/image_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();
    return Scaffold(
      appBar: const BAppBar(
        showBackArrow: true,
        title: Text('Profile'),
      ),

      /// --  Body
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Obx(() {
            final networkImage = controller.user.value.profilePicture;
            final image = networkImage.isNotEmpty ? networkImage : BImages.user;
            return Column(
              children: [
                /// Profile Picture
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      controller.imageUploading.value
                          ? const BShimmerEffect(width: 80, height: 80)
                          : BCircularImage(
                              image: image,
                              width: 80,
                              height: 80,
                              isNetworkImage: networkImage.isNotEmpty),
                      TextButton(
                        onPressed: () => controller.uploadUserProfilePicture(),
                        child: const Text('Change Profile Picture'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BSizes.spaceBtwItems / 2),
                const Divider(),
                const SizedBox(height: BSizes.spaceBtwItems),
                BSectionHeading(
                    title: 'Profile Information', showActionButton: false),
                const SizedBox(height: BSizes.spaceBtwItems),
                BProfileMenu(
                    title: 'Name',
                    value: controller.user.value.fullName,
                    onPressed: () => Get.to(() => const ChangeName())),
                BProfileMenu(
                    title: 'Username',
                    value: controller.user.value.username,
                    icon: Iconsax.copy,
                    onPressed: () {}),
                BProfileMenu(
                    title: 'Position',
                    value: 'IMS Senior Developer',
                    onPressed: () {}),
                BProfileMenu(
                    title: 'Department', value: 'IMS', onPressed: () {}),
                BProfileMenu(
                    title: 'Supervisor', value: 'MDD', onPressed: () {}),
                BProfileMenu(title: 'Manager', value: 'AJS', onPressed: () {}),
                const SizedBox(height: BSizes.spaceBtwItems / 2),
                const Divider(),
                const SizedBox(height: BSizes.spaceBtwItems),
                BSectionHeading(
                    title: 'Personal Information', showActionButton: false),
                BProfileMenu(
                    title: 'UserID',
                    value: controller.user.value.id,
                    icon: Iconsax.copy,
                    onPressed: () {}),
                BProfileMenu(
                    title: 'E-mail',
                    value: controller.user.value.email,
                    onPressed: () {}),
                BProfileMenu(
                    title: 'Cellphone Number',
                    value: controller.user.value.phoneNumber,
                    icon: Iconsax.copy,
                    onPressed: () {}),
                const Divider(),
                const SizedBox(height: BSizes.spaceBtwItems),
                Center(
                  child: TextButton(
                      onPressed: () => controller.deleteAccountWarningPopup(),
                      child: const Text('Close Account',
                          style: TextStyle(color: Colors.red))),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}
