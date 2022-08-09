import 'package:flutter/material.dart';

class SettingsEnumDropdown<T> extends StatelessWidget {
  const SettingsEnumDropdown({
    Key? key,
    required this.settingName,
    required this.dropdownItems,
    required this.value,
    required this.onChange,
  }) : super(key: key);

  final String settingName;
  final List<DropdownMenuItem<T>> dropdownItems;
  final T value;
  final void Function(T) onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(settingName),
              ),
              const Spacer(),
            ],
          ),
          DropdownButton<T>(
            items: dropdownItems,
            onChanged: (T? value) {
              if (value == null) {
                return;
              }

              onChange(value);
            },
            value: value,
          ),
        ],
      ),
    );
  }
}
