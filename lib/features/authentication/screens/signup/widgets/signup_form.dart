import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/validators/validation.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/login_signup/form_divider.dart';
import 'package:mdmpi_mobile_app/features/authentication/screens/signup/widgets/terms_conditions_checkbox.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/constants/text_string.dart';
import '../../../controllers/signup/signup_controller.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignupController>();
    return Obx(
      () => Form(
        key: controller.signupFormKey,
        child: Column(
          children: [
            /// firstname & lastname
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.firstname,
                    validator: (value) =>
                        BValidator.validateEmptyText('First name', value),
                    decoration: const InputDecoration(
                        labelText: BTexts.firstname,
                        prefixIcon: Icon(Iconsax.user)),
                  ),
                ),
                const SizedBox(width: BSizes.spaceBtwInputFields),
                Expanded(
                  child: TextFormField(
                    controller: controller.lastName,
                    validator: (value) =>
                        BValidator.validateEmptyText('Last name', value),
                    decoration: const InputDecoration(
                        labelText: BTexts.lastname,
                        prefixIcon: Icon(Iconsax.user)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Username
            TextFormField(
              controller: controller.username,
              validator: (value) =>
                  BValidator.validateEmptyText('Username', value),
              decoration: const InputDecoration(
                  labelText: BTexts.username,
                  prefixIcon: Icon(Iconsax.user_edit)),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Email
            TextFormField(
                controller: controller.email,
                validator: (value) => BValidator.validateEmail(value),
                decoration: const InputDecoration(
                    labelText: BTexts.email, prefixIcon: Icon(Iconsax.direct))),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Initial
            TextFormField(
              controller: controller.initial,
              validator: (value) =>
                  BValidator.validateEmptyText('Initial', value),
              decoration: const InputDecoration(labelText: BTexts.initial),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Department
            BDropdown(
                icon: Icons.group,
                label: 'Department',
                dropdownList: controller.departments.value
                    .map((department) => department.department)
                    .toList(),
                controller: controller.department),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Multi select
            TextFormField(
              controller: controller.selectedRole,
              onTap: () {
                BFullScreenLoader.showRoleChecklistItem(context, controller);
              },
              decoration: InputDecoration(
                  prefixIcon: Icon(Iconsax.document_code), labelText: 'Role'),
            ),

            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Mobile Number
            TextFormField(
              controller: controller.phoneNumber,
              validator: (value) => BValidator.validatePhoneNumber(value),
              decoration: const InputDecoration(
                  labelText: BTexts.mobile, prefixIcon: Icon(Iconsax.call)),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Password
            TextFormField(
              validator: (value) => BValidator.validatePassword(value),
              controller: controller.password,
              obscureText: controller.hidePassword.value,
              decoration: InputDecoration(
                  labelText: BTexts.password,
                  prefixIcon: const Icon(Iconsax.password_check),
                  suffixIcon: IconButton(
                      onPressed: () => controller.hidePassword.value =
                          !controller.hidePassword.value,
                      icon: Icon(controller.hidePassword.value
                          ? Iconsax.eye_slash
                          : Iconsax.eye))),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Agree to Policy
            const AgreeToPolicy(),
            const SizedBox(height: BSizes.spaceBtwSections),

            /// Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => controller.signup(),
                  child: const Text(BTexts.createAccount)),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
            const FormDivider(
              dividerText: "ims:jca",
            )
          ],
        ),
      ),
    );
  }
}
