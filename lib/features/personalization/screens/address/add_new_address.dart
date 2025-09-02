import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';


class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BAppBar(showBackArrow: true, title: Text('Add new Address')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(BSizes.defaultSpace),
          child: Form(
              child: Column(
            children: [
              TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.user), labelText: 'Name')),
              SizedBox(height: BSizes.spaceBtwInputFields),
              TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.mobile), labelText: 'Phone Number')),
              SizedBox(height: BSizes.spaceBtwInputFields),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.building_31), labelText: 'Street'))),
                  SizedBox(height: BSizes.spaceBtwInputFields),
                  Expanded(child: TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.code), labelText: 'Postal Code'))),
                ],
              ),
              const SizedBox(height: BSizes.spaceBtwInputFields),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.building), labelText: 'City'))),
                  SizedBox(height: BSizes.spaceBtwInputFields),
                  Expanded(child: TextFormField(decoration: InputDecoration(prefixIcon: Icon(Iconsax.activity), labelText: 'State'))),
                ],
              ),
              const SizedBox(height: BSizes.spaceBtwInputFields),
              TextFormField(decoration: const InputDecoration(prefixIcon: Icon(Iconsax.global), labelText: 'Country')),
              const SizedBox(height: BSizes.defaultSpace),
              SizedBox(width: double.infinity,child: ElevatedButton(onPressed: (){}, child: Text('Save')))
            ],
          )),
        ),
      ),
    );
  }
}
