import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/saas_palette.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PhoneCountryCode {
  final String code;
  final String name;
  final String flag;
  const PhoneCountryCode({
    required this.code,
    required this.name,
    required this.flag,
  });
}

const kPhoneCountryCodes = [
  PhoneCountryCode(code: '+57', name: 'Colombia', flag: '🇨🇴'),
  PhoneCountryCode(code: '+1', name: 'EE.UU./Canadá', flag: '🇺🇸'),
  PhoneCountryCode(code: '+34', name: 'España', flag: '🇪🇸'),
  PhoneCountryCode(code: '+52', name: 'México', flag: '🇲🇽'),
  PhoneCountryCode(code: '+54', name: 'Argentina', flag: '🇦🇷'),
  PhoneCountryCode(code: '+55', name: 'Brasil', flag: '🇧🇷'),
  PhoneCountryCode(code: '+56', name: 'Chile', flag: '🇨🇱'),
  PhoneCountryCode(code: '+51', name: 'Perú', flag: '🇵🇪'),
  PhoneCountryCode(code: '+58', name: 'Venezuela', flag: '🇻🇪'),
  PhoneCountryCode(code: '+593', name: 'Ecuador', flag: '🇪🇨'),
  PhoneCountryCode(code: '+507', name: 'Panamá', flag: '🇵🇦'),
  PhoneCountryCode(code: '+506', name: 'Costa Rica', flag: '🇨🇷'),
  PhoneCountryCode(code: '+591', name: 'Bolivia', flag: '🇧🇴'),
  PhoneCountryCode(code: '+595', name: 'Paraguay', flag: '🇵🇾'),
  PhoneCountryCode(code: '+598', name: 'Uruguay', flag: '🇺🇾'),
  PhoneCountryCode(code: '+44', name: 'Reino Unido', flag: '🇬🇧'),
  PhoneCountryCode(code: '+49', name: 'Alemania', flag: '🇩🇪'),
  PhoneCountryCode(code: '+33', name: 'Francia', flag: '🇫🇷'),
];

/// Parsea un número completo (con o sin indicativo) y retorna (countryCode, localNumber).
(String, String) parsePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final sorted = kPhoneCountryCodes.toList()
    ..sort((a, b) => b.code.length.compareTo(a.code.length));
  for (final cc in sorted) {
    final dial = cc.code.replaceAll('+', '');
    if (digits.startsWith(dial) && digits.length > dial.length) {
      return (cc.code, digits.substring(dial.length));
    }
  }
  return ('+57', digits);
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Campo de teléfono con selector de indicativo de país.
///
/// El padre gestiona el estado: pasa [countryCode] y [onCountryCodeChanged]
/// junto con el [controller] para el número local.
///
/// El número completo se obtiene con: `'$countryCode${controller.text.trim()}'`
class PhoneFormField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String label;
  final bool required;
  final bool readOnly;

  const PhoneFormField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.label = 'Teléfono',
    this.required = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.saas.border),
          ),
          child: Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  dropdownColor: context.saas.bgCanvas,
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 13,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: context.saas.textTertiary,
                    size: 18,
                  ),
                  onChanged: readOnly ? null : (v) => onCountryCodeChanged(v!),
                  items: kPhoneCountryCodes
                      .map(
                        (cc) => DropdownMenuItem(
                          value: cc.code,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${cc.flag} ${cc.code}',
                              style: TextStyle(
                                color: context.saas.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Container(width: 1, height: 24, color: context.saas.border),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Número sin indicativo',
                    hintStyle: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  validator: required
                      ? (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
