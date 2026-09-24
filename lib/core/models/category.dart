import 'package:flutter/material.dart';

enum PlazaCategoryType {
  movies,
  dining,
  events,
  activities,
  shopping,
  stays,
  sports,
}

class PlazaCategory {
  final String id;
  final String title;
  final PlazaCategoryType type;
  final IconData icon;
  final String tagline;
  final Color accentColor;
  final int activeCount;

  const PlazaCategory({
    required this.id,
    required this.title,
    required this.type,
    required this.icon,
    required this.tagline,
    required this.accentColor,
    required this.activeCount,
  });
}
