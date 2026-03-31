import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

class RecentActivitiesScreen extends StatelessWidget {
  const RecentActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activities'),
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          
          /// Filter chips
          ActivityFilterChips(
            onFilterChanged: (filter) {
              // TODO: Implement filtering logic
            },
          ),

          const SizedBox(height: BSizes.spaceBtwItems),

          /// Recent Activities List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
              children: const [
                ActivityListTile(
                  title: 'Juan Dela Cruz collected ₱5,000 from Bucket #102',
                  subtitle: '2 hours ago',
                  time: 'Today 10:30',
                  status: CollectionStatusColors.statusOngoing,
                  statusColor: Colors.orange,
                  icon: Icons.person,
                ),
                ActivityListTile(
                  title: 'Maria Santos marked Bucket #205 as Completed',
                  subtitle: '4 hours ago',
                  time: 'Today 08:15',
                  status: CollectionStatusColors.statusFullyCollected,
                  statusColor: Colors.green,
                  icon: Icons.person,
                ),
                ActivityListTile(
                  title: 'Jose Reyes reassigned Bucket #308 to Peter M.',
                  subtitle: '1 day ago',
                  time: 'Yesterday 16:12',
                  status: CollectionStatusColors.statusRescheduled,
                  statusColor: Colors.purple,
                  icon: Icons.person,
                ),
                ActivityListTile(
                  title: 'Collected from BDO',
                  subtitle: 'BDO • CHQ #001234',
                  time: 'Today 10:30',
                  status: CollectionStatusColors.statusAssigned,
                  statusColor: Colors.blue,
                  icon: Icons.account_balance,
                  amount: '₱25,000.00',
                ),
                ActivityListTile(
                  title: 'Payment received',
                  subtitle: 'GCash • Ref #98765',
                  time: 'Yesterday 16:12',
                  status: CollectionStatusColors.statusFullyCollected,
                  statusColor: Colors.green,
                  icon: Icons.mobile_friendly,
                  amount: '₱1,250.00',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
