import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/event_model.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';
import '../../controllers/event_controller.dart';

class InviteContacts extends ConsumerStatefulWidget {
  final String eventId;

  const InviteContacts({super.key, required this.eventId});

  @override
  ConsumerState<InviteContacts> createState() => _InviteContactsState();
}

class _InviteContactsState extends ConsumerState<InviteContacts> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final eventAsyncValue = ref.watch(eventProvider(widget.eventId));

    return eventAsyncValue.when(
      data: (event) => _buildScreen(event),
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (err, stack) =>
              Scaffold(body: Center(child: Text('Error loading event: $err'))),
    );
  }

  Widget _buildScreen(EventModel event) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(event),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: event.eventTitle,
                    textAlign: TextAlign.start,
                  ),
                  _buildLocationRow(event),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                    height: 40.0,
                  ),
                  _buildDateTimeRow(event),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                    height: 40.0,
                  ),
                  _buildDescriptionSection(event),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                    height: 40.0,
                  ),
                  _buildPriceSection(event),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: FullWidthButton(
                icon: const Icon(Icons.check),
                name: 'Confirm Event',
                onPressed: () => _confirmEvent(event.eventId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EventModel event) {
    return Stack(
      children: [
        // Event Image or Placeholder
        Container(
          height: MediaQuery.of(context).size.height * 0.25,
          width: double.infinity,
          color: AppColors.secondaryBackground,
          child:
              event.venueImages.isNotEmpty
                  ? Image.network(event.venueImages[0], fit: BoxFit.cover)
                  : const Center(
                    child: Icon(
                      Icons.image,
                      size: 80,
                      color: AppColors.grayBorder,
                    ),
                  ),
        ),
        // Top Navigation
        Positioned(
          top: 15.0,
          left: 15.0,
          right: 15.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  height: 32.0,
                  width: 32.0,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 18.0,
                        color: AppColors.primaryBackground,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  height: 32.0,
                  width: 32.0,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.primaryBackground,
                    size: 18.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom info (seats left)
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(36.0),
                  ),
                  child: const Text(
                    '4 seats left',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryWhite,
                    ),
                  ),
                ),
                if (event.venueImages.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        event.venueImages.asMap().entries.map((entry) {
                          return Container(
                            width: 10.0,
                            height: 10.0,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4.0,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  current == entry.key
                                      ? AppColors.primaryWhite
                                      : AppColors.secondaryWhite,
                            ),
                          );
                        }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(EventModel event) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primaryWhite),
            const SizedBox(width: 5.0),
            Text(
              event.nameOfVenue,
              style: const TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Icon(Icons.edit, color: AppColors.secondaryWhite),
      ],
    );
  }

  Widget _buildDateTimeRow(EventModel event) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.primaryWhite,
            ),
            const SizedBox(width: 5.0),
            Text(
              formatDate(event.eventDateTime),
              style: const TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Icon(Icons.edit, color: AppColors.secondaryWhite),
      ],
    );
  }

  Widget _buildDescriptionSection(EventModel event) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.eventDescription,
          style: const TextStyle(fontSize: 16.0, color: AppColors.primaryWhite),
        ),
        const Icon(Icons.edit, color: AppColors.secondaryWhite),
      ],
    );
  }

  Widget _buildPriceSection(EventModel event) {
    return Row(
      children: [
        SvgPicture.asset('assets/svg/male_icon.svg'),
        const SizedBox(width: 10.0),
        Text(
          '\$ ${event.priceMen.toStringAsFixed(0)}',
          style: const TextStyle(color: AppColors.primaryWhite, fontSize: 16.0),
        ),
        const SizedBox(width: 10.0),
        const Text(
          '|',
          style: TextStyle(
            color: Color.fromRGBO(52, 52, 52, 1.0),
            fontSize: 18.0,
          ),
        ),
        const SizedBox(width: 10.0),
        SvgPicture.asset('assets/svg/female_icon.svg'),
        const SizedBox(width: 10.0),
        Text(
          '\$ ${event.priceWomen.toStringAsFixed(0)}',
          style: const TextStyle(color: AppColors.primaryWhite, fontSize: 16.0),
        ),
      ],
    );
  }

  void _confirmEvent(String eventId) async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(eventId, 'isDraft', false);

      if (!mounted) return;
      Navigator.of(context).pushNamed('/invite-success');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error confirming event: $e')));
    }
  }
}

// Helper function to format date
String formatDate(DateTime date) {
  final months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final amPm = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month]}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
}
