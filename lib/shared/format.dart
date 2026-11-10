import '../data/models.dart';

const _months = [
  'янв.', 'февр.', 'марта', 'апр.', 'мая', 'июня',
  'июля', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.',
];

/// `12 400`
String formatNumber(int value) {
  final digits = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// `6 000 ₸`
String formatPrice(int value) => '${formatNumber(value)} ₸';

/// `14 сент. 2026`
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// `14 сент. 2026, 09:05`
String formatDateTime(DateTime d) =>
    '${formatDate(d)}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Склонение: plural(3, 'дерево', 'дерева', 'деревьев') → «дерева».
String plural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return few;
  return many;
}

String treesCount(int n) => '$n ${plural(n, 'дерево', 'дерева', 'деревьев')}';

String treeStatusLabel(TreeStatus s) => switch (s) {
      TreeStatus.growing => 'Растёт',
      TreeStatus.awaitingPlanting => 'Ожидает посадки',
      TreeStatus.planted => 'Посажено',
      TreeStatus.monitoring => 'На мониторинге',
    };

String orderStatusLabel(OrderStatus s) => switch (s) {
      OrderStatus.created => 'Создан',
      OrderStatus.confirmed => 'Принят',
      OrderStatus.completed => 'Выполнен',
      OrderStatus.cancelled => 'Отменён',
    };
