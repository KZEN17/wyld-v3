import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class NumberOfGuests extends ConsumerStatefulWidget {
  final String eventId;

  const NumberOfGuests({super.key, required this.eventId});

  @override
  ConsumerState<NumberOfGuests> createState() => _NumberOfGuestsState();
}

class _NumberOfGuestsState extends ConsumerState<NumberOfGuests> {
  int selectedWomen = 4;
  int selectedMen = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle(
              title: "How Many \nGuests?",
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            _buildGuestRow(
              'Women',
              Image.asset(
                'assets/icons/female.png',
                height: 36.0,
                width: 36.0,
                fit: BoxFit.cover,
              ),
              selectedWomen,
              (val) {
                setState(() {
                  selectedWomen = val;
                });
              },
            ),
            const SizedBox(height: 40.0),
            _buildGuestRow(
              'Men',
              Image.asset(
                'assets/icons/male.png',
                height: 36.0,
                width: 36.0,
                fit: BoxFit.cover,
              ),
              selectedMen,
              (val) {
                setState(() {
                  selectedMen = val;
                });
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FullWidthButton(
                name: 'Confirm Number',
                onPressed: _saveGuestNumbers,
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(
    String title,
    Widget icon,
    int selectedValue,
    Function(int) onChanged,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(50.0),
          ),
          width: MediaQuery.of(context).size.width * 0.8,
          child: CarouselSlider.builder(
            itemCount: 11, // 0-10 guests
            itemBuilder: (BuildContext context, int index, int realIndex) {
              return Container(
                height: 36.0,
                width: 36.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      index == selectedValue ? AppColors.mainGradient : null,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 26.0,
                      color: AppColors.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              onPageChanged: (index, reason) {
                onChanged(index);
              },
              height: 50,
              enlargeCenterPage: false,
              viewportFraction: 0.18,
              initialPage: selectedValue,
              scrollDirection: Axis.horizontal,
              enableInfiniteScroll: true,
            ),
          ),
        ),
      ],
    );
  }

  void _saveGuestNumbers() async {
    try {
      final guestsMap = {'women': selectedWomen, 'men': selectedMen};

      await ref
          .read(eventControllerProvider.notifier)
          .updateEventField(widget.eventId, 'numberOfGuests', guestsMap);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamed('/price-screen', arguments: widget.eventId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving guest numbers: $e')));
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
