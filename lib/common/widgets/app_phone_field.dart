import 'dart:io';

import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/validators.dart';

import 'app_text.dart';

class AppPhoneField extends StatelessWidget {
  final TextEditingController? controllerCode;
  final TextEditingController? controllerPhone;
  final String text;
  final double fontSize;
  final Color? textColor;
  final FontWeight fontWeight;
  final String? hintTextCode;
  final String? hintTextPhone;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final AppTextFieldType type;

  const AppPhoneField({
    super.key,
    required this.text,
    this.hintTextCode,
    this.hintTextPhone,
    this.controllerCode,
    this.controllerPhone,
    this.inputFormatters,
    this.obscureText = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.type = AppTextFieldType.withoutBorder,
    this.fontSize = 14.0,
    this.textColor = AppColors.kPrimary500,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    if (type == AppTextFieldType.withoutBorder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText(text, color: textColor, fontSize: fontSize, fontWeight: fontWeight),
          const Gap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 30,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45, width: 1),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  ),
                  child: SizedBox(
                    height: Platform.isWindows ? 46 : 56, // Todo: Should be dynamic based on the TextFormField height
                    child: CountryPickerDropdown(
                      initialValue: 'MX',
                      itemBuilder: (Country country) => Row(
                        children: <Widget>[
                          SizedBox(width: 25, height: 12, child: CountryPickerUtils.getDefaultFlagImage(country)),
                          Gap(5),
                          Text("+${country.phoneCode}", style: TextStyle(fontSize: 12, color: Colors.black87)),
                          // Text("(${country.isoCode})", style: TextStyle(fontSize: 6, color: Colors.black45)),
                        ],
                      ),
                      itemFilter: (Country country) => ['MX'].contains(country.isoCode),
                      priorityList: [CountryPickerUtils.getCountryByIsoCode('MX')],
                      sortComparator: (Country a, Country b) => a.isoCode.compareTo(b.isoCode),
                      onValuePicked: (Country country) {
                        if (controllerCode != null) {
                          controllerCode!.text = country.phoneCode;
                        }
                      },
                    ),
                  ),
                ),
                // child: TextFormField(
                //   controller: controllerCode,
                //   decoration: InputDecoration(
                //     hintText: hintTextCode,
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                //     ),
                //     focusedBorder: OutlineInputBorder(
                //       borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                //       borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
                //     ),
                //     prefixIcon: prefixIcon,
                //     suffixIcon: suffixIcon,
                //   ),
                //   cursorColor: AppColors.kPrimary500,
                //   validator: (value) => ValidatorsUtil.validatePhoneCode(value),
                //   inputFormatters: inputFormatters,
                //   keyboardType: TextInputType.text,
                //   obscureText: obscureText,
                //   onChanged: onChanged,
                // ),
              ),
              Flexible(
                flex: 70,
                child: TextFormField(
                  controller: controllerPhone,
                  decoration: InputDecoration(
                    hintText: hintTextPhone,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                      borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
                    ),
                    prefixIcon: prefixIcon,
                    suffixIcon: suffixIcon,
                  ),
                  cursorColor: AppColors.kPrimary500,
                  validator: (value) => ValidatorsUtil.validatePhone(value),
                  inputFormatters: inputFormatters,
                  keyboardType: TextInputType.phone,
                  obscureText: obscureText,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 30,
          child: TextFormField(
            controller: controllerCode,
            decoration: InputDecoration(
              hintText: hintTextCode,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
            cursorColor: AppColors.kPrimary500,
            validator: (value) => ValidatorsUtil.validatePhoneCode(value),
            inputFormatters: inputFormatters,
            keyboardType: TextInputType.text,
            obscureText: obscureText,
            onChanged: onChanged,
          ),
        ),
        Flexible(
          flex: 70,
          child: TextFormField(
            controller: controllerPhone,
            decoration: InputDecoration(
              hintText: hintTextPhone,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
            cursorColor: AppColors.kPrimary500,
            validator: (value) => ValidatorsUtil.validatePhone(value),
            inputFormatters: inputFormatters,
            keyboardType: TextInputType.phone,
            obscureText: obscureText,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

enum AppTextFieldType { withBorder, withoutBorder }
