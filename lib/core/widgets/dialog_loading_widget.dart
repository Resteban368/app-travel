// ignore_for_file: file_names

import 'dart:ui';

import 'package:agente_viajes/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DialogLoadingNetwork extends StatelessWidget {
  const DialogLoadingNetwork({super.key, required this.titel});

  final String titel;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(139, 42, 111, 151),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cobalt.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                height: 80,
                width: 80,
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: Text(
                  titel,
                  style: TextStyle(color: AppColors.cobalt, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'Espera un momento...',
                style: TextStyle(color: AppColors.cobaltLight, fontSize: 12),
              ),
              // Text(titel, style: TextStyle(color: grey, fontSize: 9)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: CircularProgressIndicator(color: AppColors.cobalt)),
          ],
        ),
      ),
    );
  }
}
