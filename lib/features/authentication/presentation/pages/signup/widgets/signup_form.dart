import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/base/utils/validators/validation.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/dropdown.dart';
import 'package:mdmpi_mobile_app/common/widgets/login_signup/form_divider.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/pages/signup/widgets/terms_conditions_checkbox.dart';

import '../../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../../base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';

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
                    focusNode: controller.firstnameFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(controller.lastNameFocus),
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(controller.lastNameFocus),
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
                    focusNode: controller.lastNameFocus,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(controller.usernameFocus),
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(controller.usernameFocus),
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
              focusNode: controller.usernameFocus,
              textInputAction: TextInputAction.next,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(controller.emailFocus),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(controller.emailFocus),
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
                focusNode: controller.emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(controller.initialFocus),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(controller.initialFocus),
                validator: (value) => BValidator.validateEmail(value),
                decoration: const InputDecoration(
                    labelText: BTexts.email, prefixIcon: Icon(Iconsax.direct))),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Initial
            TextFormField(
              controller: controller.initial,
              focusNode: controller.initialFocus,
              textInputAction: TextInputAction.next,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(controller.selectedRoleFocus),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(controller.selectedRoleFocus),
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
                controller: controller.department,
                // Make department required. The BDropdown passes the selected
                // value to the validator; when null or empty we'll show the
                // standard required error text.
                validator: (value) => BValidator.validateEmptyText('Department', value?.toString()),
                ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Multi select
            TextFormField(
              controller: controller.selectedRole,
              focusNode: controller.selectedRoleFocus,
              readOnly: true,
              textInputAction: TextInputAction.next,
              onTap: () {
                BFullScreenLoader.showRoleChecklistItem(context, controller);
              },
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(controller.phoneNumberFocus),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(controller.phoneNumberFocus),
              // Make role required. Since the field is read-only we validate
              // against the backing controller text.
              validator: (value) => BValidator.validateEmptyText('Role', controller.selectedRole.text),
              decoration: InputDecoration(
                  prefixIcon: Icon(Iconsax.document_code),
                  labelText: 'Role',
                  // show a red outline when validation fails so the required
                  // state is visually obvious
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  )),
            ),

            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Mobile Number
            TextFormField(
              controller: controller.phoneNumber,
              focusNode: controller.phoneNumberFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(controller.passwordFocus),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(controller.passwordFocus),
              validator: (value) => BValidator.validatePhoneNumber(value),
              decoration: const InputDecoration(
                  labelText: BTexts.mobile, prefixIcon: Icon(Iconsax.call)),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            /// Password
            TextFormField(
              validator: (value) => BValidator.validatePassword(value),
              controller: controller.password,
              focusNode: controller.passwordFocus,
              obscureText: controller.hidePassword.value,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => controller.signup(),
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
