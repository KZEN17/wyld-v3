import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class EventDateTime extends ConsumerStatefulWidget {
  final String eventId;

  const EventDateTime({super.key, required this.eventId});

  @override
  ConsumerState<EventDateTime> createState() => _EventDateTimeState();
}

class _EventDateTimeState extends ConsumerState<EventDateTime> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Column(
        children: [
          const SectionTitle(
            title: 'What date \nand time?',
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 1),
          const Center(
            child: Text(
              'Date',
              style: TextStyle(color: AppColors.primaryWhite, fontSize: 16.0),
            ),
          ),
          const SizedBox(height: 10.0),
          GestureDetector(
            onTap: () async {
              await _selectDate(context);
            },
            child: Container(
              height: 55.0,
              width: 210.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.grayBorder),
              ),
              child: Center(
                child: Text(
                  DateFormat('dd MMMM').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryWhite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30.0),
          const Center(
            child: Text(
              'Time',
              style: TextStyle(color: AppColors.primaryWhite, fontSize: 16.0),
            ),
          ),
          const SizedBox(height: 10.0),
          GestureDetector(
            onTap: () async {
              await _selectTime(context);
            },
            child: Container(
              height: 55.0,
              width: 210.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.grayBorder),
              ),
              child: Center(
                child: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryWhite,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
          FullWidthButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20.0,
            ),
            name: 'Confirm date and time',
            onPressed: _saveDateAndTime,
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              onPrimary: AppColors.primaryWhite,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPink,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: AppColors.primaryBackground,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(color: AppColors.primaryBackground),
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: CupertinoDatePicker(
              backgroundColor: AppColors.primaryBackground,
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                selectedTime.hour,
                selectedTime.minute,
              ),
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  selectedTime = TimeOfDay.fromDateTime(newDateTime);
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _saveDateAndTime() async {
    try {
      // Combine date and time
      final eventDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Save to Appwrite
      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(
            widget.eventId,
            'eventDateTime',
            eventDateTime.toIso8601String(),
          );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/event-details', arguments: widget.eventId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving date and time: $e')));
    }
  }

  void _deleteEvent() async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }
}
