import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/request_modal_widgets/b_document_reference_list.dart';

class RequestModalScaffold extends StatelessWidget {
  const RequestModalScaffold({
    super.key,
    this.header,
    this.title,
    this.subtitle,
    this.documentReferences = const <String>[],
    this.children = const <Widget>[],
    this.bottomAction,
    this.docsBottomDivider = false,
  });

  final Widget? header;

  final String? title;

  final String? subtitle;

  final List<String> documentReferences;
  final List<Widget> children;
  final Widget? bottomAction;

  final bool docsBottomDivider;

  @override
  Widget build(BuildContext context) {
    final bool dark = BHelperFunctions.isDarkMode(context);
    final Color textColor = dark ? BColors.light : BColors.black;

    return BRoundedContainer(
      backgroundColor: dark ? BColors.black : BColors.light,
      radius: 0,
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
              child: header ?? _DefaultHeader(title: title ?? '', subtitle: subtitle ?? '', textColor: textColor),
            ),
            const SizedBox(height: BSizes.xs),
            const Divider(),
            const SizedBox(height: BSizes.xs),
            // Document references
            if (documentReferences.isNotEmpty)
              DocumentReferenceList(
                documentReferences: documentReferences,
                textColor: textColor,
              ),
            if (documentReferences.isNotEmpty)
              docsBottomDivider
                  ? Column(
                      children: const [
                        SizedBox(height: BSizes.spaceBtwSections),
                        Divider(),
                        SizedBox(height: BSizes.spaceBtwSections),
                      ],
                    )
                  : const SizedBox(height: BSizes.spaceBtwSections),
            // Body
            ...children,
            const SizedBox(height: BSizes.xs),
            if (bottomAction != null)
              SafeArea(
                top: false,
                child: bottomAction!,
              ),
            const SizedBox(height: BSizes.xs),
          ],
        ),
      ),
    );
  }
}

class _DefaultHeader extends StatelessWidget {
  const _DefaultHeader({required this.title, required this.subtitle, required this.textColor});
  final String title;
  final String subtitle;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BProductTitleText(
          title: title,
          maxLines: 2,
          bold: true,
          fontColor: textColor,
        ),
        if (subtitle.isNotEmpty)
          BProductTitleText(
            title: subtitle,
            maxLines: 2,
            smallSize: true,
            fontColor: textColor,
          ),
      ],
    );
  }
}
