import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/b_request_form.dart';

import '../../../../base/utils/constants/text_string.dart';

class RequestForm extends StatelessWidget {
  const RequestForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BAppBar(
        title: Text('How would you like to start?'),
        showBackArrow: true,
      ),
      body: BRequestForm(
          labels: BTexts.requestFormLabels,
          pages: AppRoutes.requestFormPages,
          iconPaths: BImages.requestFormIconPaths),
    );
  }
}
