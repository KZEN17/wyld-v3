import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class PriceScreen extends ConsumerStatefulWidget {
  final String eventId;

  const PriceScreen({super.key, required this.eventId});

  @override
  ConsumerState<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends ConsumerState<PriceScreen> {
  final _menPriceController = TextEditingController(text: '10');
  final _womenPriceController = TextEditingController(text: '10');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _menPriceController.dispose();
    _womenPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CreateTabAppbar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SectionTitle(
              title: 'How much \nper head?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40.0),
            _buildGuestRow(
              'Women',
              Image.asset(
                'assets/icons/female.png',
                height: 36.0,
                width: 36.0,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              height: 76.0,
              width: 200.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.grayBorder),
              ),
              child: Center(
                child: TextFormField(
                  controller: _womenPriceController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.primaryPink,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 36.0,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "\$",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 36.0,
                        ),
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grayBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondaryWhite),
                    ),
                    contentPadding: const EdgeInsets.all(10.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            _buildGuestRow(
              'Men',
              Image.asset(
                'assets/icons/male.png',
                height: 36.0,
                width: 36.0,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20.0),
            Container(
              height: 76.0,
              width: 200.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.grayBorder),
              ),
              child: Center(
                child: TextFormField(
                  controller: _menPriceController,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.primaryPink,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 36.0,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "\$",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 36.0,
                        ),
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.grayBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.secondaryWhite),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Note: Price cannot be changed.',
              style: TextStyle(color: AppColors.primaryWhite, fontSize: 18.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40.0),
            FullWidthButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20.0,
              ),
              name: 'Confirm Cost',
              onPressed: _savePrices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRow(String title, Widget icon) {
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
      ],
    );
  }

  void _savePrices() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save men price
        await ref
            .read(eventControllerProvider.notifier)
            .updateEventField(
              widget.eventId,
              'priceMen',
              double.parse(_menPriceController.text),
            );

        // Save women price
        await ref
            .read(eventControllerProvider.notifier)
            .updateEventField(
              widget.eventId,
              'priceWomen',
              double.parse(_womenPriceController.text),
            );

        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamed('/event-image-upload', arguments: widget.eventId);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving prices: $e')));
      }
    }
  }
}
