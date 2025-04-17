import 'package:flutter/material.dart';
import 'package:wyld/core/constants/app_colors.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Bookings Screen',
              style: TextStyle(color: AppColors.primaryWhite),
            ),
          ),
        ],
      ),
    );
  }
}
