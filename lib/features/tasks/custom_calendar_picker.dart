import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'module_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final List<Module> modules;
  final ValueChanged<DateTime> onDateChanged;

  const CustomCalendarPicker({
    super.key,
    required this.initialDate,
    required this.modules,
    required this.onDateChanged,
  });

  @override
  State<CustomCalendarPicker> createState() => _CustomCalendarPickerState();
}

class _CustomCalendarPickerState extends State<CustomCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + increment,
      );
    });
  }

  bool _hasDeadline(DateTime date) {
    return widget.modules.any((m) {
      if (m.rawDueDate == null) return false;
      final d = m.rawDueDate!;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${months[_currentMonth.month]} ${_currentMonth.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevronRight),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Days of week
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
              .map(
                (day) => SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Days Grid
        _buildDaysGrid(),
      ],
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final firstWeekday =
        firstDayOfMonth.weekday % 7; // 0 for Sunday, 1 for Monday...
    // Note: DateTime.weekday returns 1 for Mon, 7 for Sun.
    // We want Sun=0, Mon=1...Sat=6 if our header starts with Sun.
    // However, typical DateTime.weekday: Mon=1..Sun=7.
    // Let's align with header ['Min', 'Sen'...] -> Sun, Mon...
    // Sun is 7 in DateTime. So 7%7 = 0. Mon is 1%7 = 1. Correct.

    final totalSlots = firstWeekday + daysInMonth;
    final totalRows = (totalSlots / 7).ceil();

    return Column(
      children: List.generate(totalRows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final dayOffset = rowIndex * 7 + colIndex - firstWeekday;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox(width: 32, height: 32);
              }

              final day = dayOffset + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final hasDot = _hasDeadline(date);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  widget.onDateChanged(date);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isToday ? AppColors.primary : null),
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                      if (hasDot)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
