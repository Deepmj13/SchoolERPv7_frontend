const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

enum DateFormatStyle { short, shortDayFirst, numeric }

String formatDateFromIso(
  String? iso, {
  DateFormatStyle style = DateFormatStyle.short,
  String prefix = '',
}) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return prefix.isNotEmpty ? '$prefix$iso' : iso;
  final month = _months[dt.month - 1];
  switch (style) {
    case DateFormatStyle.short:
      return '$prefix$month ${dt.day}, ${dt.year}';
    case DateFormatStyle.shortDayFirst:
      return '$prefix${dt.day} $month ${dt.year}';
    case DateFormatStyle.numeric:
      return '${dt.day}/${dt.month}/${dt.year}';
  }
}