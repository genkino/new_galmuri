import 'package:flutter/material.dart';

enum BoardType {
  all,
  clien,
  ddanzi,
  theqoo,
  etoland,
  dcinside,
  bobaedream;

  String get displayName {
    switch (this) {
      case BoardType.all:
        return '전체보기';
      case BoardType.clien:
        return '클리앙';
      case BoardType.ddanzi:
        return '딴지일보';
      case BoardType.theqoo:
        return '더쿠';
      case BoardType.etoland:
        return '이토랜드';
      case BoardType.dcinside:
        return '디씨인사이드';
      case BoardType.bobaedream:
        return '보배드림';
    }
  }

  String get serviceKey {
    switch (this) {
      case BoardType.all:
        return 'all';
      case BoardType.clien:
        return 'clien';
      case BoardType.ddanzi:
        return 'ddanzi';
      case BoardType.theqoo:
        return 'theqoo';
      case BoardType.etoland:
        return 'etoland';
      case BoardType.dcinside:
        return 'dcinside';
      case BoardType.bobaedream:
        return 'bobaedream';
    }
  }

  Color get color {
    switch (this) {
      case BoardType.all:
        return Colors.blue;
      case BoardType.clien:
        return Color(0xFF2196F3);  // 클리앙 메인 색상
      case BoardType.ddanzi:
        return Color(0xFF4CAF50);  // 딴지일보 메인 색상
      case BoardType.theqoo:
        return Color(0xFFE91E63);  // 더쿠 메인 색상
      case BoardType.etoland:
        return Color(0xFF4CAF50);  // 이토랜드 메인 색상
      case BoardType.dcinside:
        return Color(0xFF1E88E5);  // 디시인사이드 메인 색상
      case BoardType.bobaedream:
        return Color(0xFF795548);  // 보배드림 메인 색상
    }
  }
} 