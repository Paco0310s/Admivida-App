import 'package:flutter/material.dart';

class AppColors {
  static const List<Color> genoaPalette = [
    Color(0xFFf2fbf8),
    Color(0xFFd5f2ea),
    Color(0xFFaae5d6),
    Color(0xFF78d0bd),
    Color(0xFF4cb5a2),
    Color(0xFF329a88),
    Color(0xFF247569),
    Color(0xFF22635a),
    Color(0xFF1f504a),
    Color(0xFF1e433f),
    Color(0xFF0c2724),
  ];

  //---------------Base Colors-------------------

  static const Color kPrimaryColor = Color(0xFF1F4554);
  static const Color kSecondaryColor = Color(0xFF247569);
  static const Color kTertiaryColor = Color(0xFF28668C);
  static const Color kBackgroundColor = Color(0xFFF5F5F5);
  static const Color kBlackColor = Color(0xff000000);
  static const Color kWhiteColor = Color(0xffffffff);

  //---------------Primary Colors----------------
  static const Color kPrimary50 = Color(0xFFd5f2ea);
  static const Color kPrimary100 = Color(0xFFaae5d6);
  static const Color kPrimary200 = Color(0xFF78d0bd);
  static const Color kPrimary300 = Color(0xFF4cb5a2);
  static const Color kPrimary400 = Color(0xFF329a88);
  static const Color kPrimary500 = Color(0xFF247569);
  static const Color kPrimary600 = Color(0xFF22635a);
  static const Color kPrimary700 = Color(0xFF1f504a);
  static const Color kPrimary800 = Color(0xFF1e433f);
  static const Color kPrimary900 = Color(0xFF0c2724);

  //---------------Neutral Colors---------------
  static const Color kNeutral50 = Color(0xffF6F6F6);
  static const Color kNeutral100 = Color(0xffF5F5F5);
  static const Color kNeutral200 = Color(0xffE5E5E5);
  static const Color kNeutral300 = Color(0xffD4D4D4);
  static const Color kNeutral400 = Color(0xffA3A3A3);
  static const Color kNeutral500 = Color(0xff737373);
  static const Color kNeutral600 = Color(0xff525252);
  static const Color kNeutral700 = Color(0xff404040);
  static const Color kNeutral800 = Color(0xff262626);
  static const Color kNeutral900 = Color(0xff171717);

  //---------------Success Colors---------------//
  static const Color kSuccess = Color(0xff00B243);
  static final Color kSuccess20Op = kSuccess.withValues(alpha: 0.20);

  //---------------Info Colors---------------//
  static const Color kInfo = Color(0xff1D4ED8);
  static final Color kInfo20Op = kInfo.withValues(alpha: 0.20);

  //---------------Warning Colors---------------//
  static const Color kWarning = Color(0xffFD7F0B);
  static final Color kWarning20Op = kWarning.withValues(alpha: 0.20);

  //---------------Error Colors---------------//
  static const Color kError = Color(0xffE40F0F);
  static final Color kError20Op = kError.withValues(alpha: 0.20);

  //---------------Dark Colors---------------//
  static const Color kDark1 = Color(0xff0F172A);
  static const Color kDark2 = Color(0xff1E293B);
  static const Color kDark3 = Color.fromARGB(255, 51, 85, 71);
}
