import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

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
      appBar: AppBar(
        title: const Text('Collection Calendar'),
      ),
      body: Obx(() {
        // This Obx ensures the calendar reacts to data changes in the controller
        // ignore: unused_local_variable
        final dummy = controller.allRecentHistory.length; 
        
        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
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
                formatButtonVisible: true,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            const Divider(),
            
            Expanded(
              child: _buildEventList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final dayActivities = _getEventsForDay(_selectedDay!);

    if (dayActivities.isEmpty) {
      return const Center(
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
      );
    }

    final historyList = dayActivities.map((e) => e['history'] as CollectionHistoryModel).toList();
    final accountNames = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['accountName'].toString() };
    final invoiceIds = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['invoiceId'].toString() };
    final items = { for (var i = 0; i < dayActivities.length; i++) i : dayActivities[i]['item'] as CollectionItemModel };

    return SingleChildScrollView(
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
