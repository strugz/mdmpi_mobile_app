import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/home/widgets/home_appbar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/activity_type_modal.dart';

class CollectionCalendarScreen extends StatefulWidget {
  const CollectionCalendarScreen({super.key});

  @override
  State<CollectionCalendarScreen> createState() => _CollectionCalendarScreenState();
}

class _CollectionCalendarScreenState extends State<CollectionCalendarScreen> {
  final controller = Get.find<CollectionActivityController>();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return controller.activitiesByDate[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Obx(() {
          // This Obx ensures the calendar reacts to data changes in the controller
          // ignore: unused_local_variable
          final dummy = controller.allRecentHistory.length; 
          
          return Column(
            children: [
              // Header
              const BPrimaryHeaderContainer(
                child: Column(
                  children: [
                    BHomeAppBar(title: 'Calendar'),
                    SizedBox(height: BSizes.spaceBtwSections),
                  ],
                ),
              ),

              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: BColors.accent,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: BColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) => const SizedBox.shrink(),
                  defaultBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    if (events.isNotEmpty) {
                      return _buildCalendarDay(day, BColors.success);
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    if (events.isNotEmpty) {
                      return _buildCalendarDay(day, BColors.success, isToday: true);
                    }
                    return null;
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    return _buildCalendarDay(
                      day, 
                      BColors.primary, 
                      hasActivity: events.isNotEmpty,
                      isSelected: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwItems),

              // Add Activity Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
                        ),
                        builder: (_) => const ActivityTypeModal(),
                      );
                    },
                    icon: const Icon(Iconsax.add_circle, size: 20),
                    label: const Text('Add Activity'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: BSizes.md),
                      backgroundColor: BColors.primary.withValues(alpha: 0.1),
                      foregroundColor: BColors.primary,
                      side: const BorderSide(color: BColors.primary),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: BSizes.spaceBtwItems),
              const Divider(),
              
              _buildEventList(),
            ],
          );
        }),
      ),
    );
  }

  /// Helper to build a decorated calendar day
  Widget _buildCalendarDay(DateTime day, Color color, {bool isToday = false, bool hasActivity = false, bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: (isSelected && hasActivity)
          ? Border.all(color: BColors.success, width: 2)
          : (isToday ? Border.all(color: BColors.accent, width: 2) : null),
      ),
      child: Text(
        '${day.day}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final dayActivities = _getEventsForDay(_selectedDay!);

    if (dayActivities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 48, color: BColors.darkGrey),
              SizedBox(height: BSizes.sm),
              Text(
                'No activities recorded for this day.',
                style: TextStyle(color: BColors.darkGrey),
              ),
            ],
          ),
        ),
      );
    }

    final historyList = dayActivities.map((e) => e['history'] as CollectionHistoryModel).toList();
    final accountNames = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['accountName'].toString() };
    final invoiceIds = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['invoiceId']?.toString() };
    final items = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['item'] as CollectionItemModel? };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BSizes.md),
            child: Text(
              'Activities on ${DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day).toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ActivityHistoryList(
            history: historyList,
            accountNames: accountNames,
            invoiceIds: invoiceIds,
            items: items,
          ),
          const SizedBox(height: BSizes.spaceBtwSections),
        ],
      ),
    );
  }
}
