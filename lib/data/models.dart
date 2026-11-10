import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Простые immutable-модели для прототипа. На этапе MVP заменим на freezed.

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.registeredAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime registeredAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}

class TreeSpecies {
  const TreeSpecies({
    required this.id,
    required this.name,
    required this.latinName,
    required this.shortDescription,
    required this.description,
    required this.price,
    required this.co2PerYear,
    required this.heightLabel,
    required this.icon,
    required this.tint,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final String latinName;
  final String shortDescription;
  final String description;

  /// Стоимость посадки в тенге.
  final int price;

  /// Условное поглощение CO₂, кг в год.
  final int co2PerYear;
  final String heightLabel;

  /// Иконка-иллюстрация вместо фото в прототипе.
  final IconData icon;

  /// Фон иллюстрации.
  final Color tint;
  final bool isPopular;
}

/// Что входит в посадку (из финмодели презентации, 6 000 ₸).
class PlantingIncludes {
  const PlantingIncludes(this.title, this.icon);
  final String title;
  final IconData icon;
}

enum OrderStatus { created, confirmed, completed, cancelled }

/// «Сразу» — оплата целиком; «Копить» — взносами, дерево растёт до 100%.
enum PaymentMode { full, installments }

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.speciesId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.status,
    required this.treeIds,
    this.paymentMode = PaymentMode.full,
    this.installment,
  });

  final String id;

  /// Человекочитаемый номер заказа, например `№ 1042`.
  final int number;
  final String speciesId;
  final int quantity;
  final int unitPrice;
  final DateTime createdAt;
  final OrderStatus status;
  final List<String> treeIds;
  final PaymentMode paymentMode;

  /// Размер ежемесячного взноса для режима «Копить».
  final int? installment;

  int get total => quantity * unitPrice;

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        number: number,
        speciesId: speciesId,
        quantity: quantity,
        unitPrice: unitPrice,
        createdAt: createdAt,
        status: status ?? this.status,
        treeIds: treeIds,
        paymentMode: paymentMode,
        installment: installment,
      );
}

/// growing — копим взносами (виртуальный рост 0–100%),
/// awaitingPlanting — оплачено, ждёт исполнителя, дальше — реальное дерево.
enum TreeStatus { growing, awaitingPlanting, planted, monitoring }

/// Стадии виртуального роста по проценту оплаты.
enum GrowthStage {
  seed('Семя'),
  sprout('Росток'),
  sapling('Саженец'),
  young('Молодое'),
  ready('Готово');

  const GrowthStage(this.label);
  final String label;

  static GrowthStage fromProgress(double p) {
    final pct = (p * 100).round();
    if (pct >= 100) return ready;
    if (pct >= 60) return young;
    if (pct >= 40) return sapling;
    if (pct >= 20) return sprout;
    return seed;
  }
}

enum TreeEventType { ordered, topUp, grown, planted, watered, checked, note }

class TreeEvent {
  const TreeEvent({
    required this.type,
    required this.date,
    required this.title,
    this.note,
    this.author,
  });

  final TreeEventType type;
  final DateTime date;
  final String title;
  final String? note;
  final String? author;
}

class Tree {
  const Tree({
    required this.id,
    required this.code,
    required this.speciesId,
    required this.orderId,
    required this.status,
    required this.orderedAt,
    required this.events,
    this.name,
    this.paidAmount = 0,
    this.targetAmount = 0,
    this.isMine = true,
    this.plantedAt,
    this.location,
    this.locationName,
    this.plantedBy,
    this.photoCount = 0,
  });

  final String id;

  /// Индивидуальный номер, `PT-ALM-000123`.
  final String code;
  final String speciesId;
  final String orderId;
  final TreeStatus status;
  final DateTime orderedAt;
  final List<TreeEvent> events;

  /// Имя, которое дал пользователь: «Листик».
  final String? name;

  /// Сколько уже внесено и сколько нужно для посадки, ₸.
  final int paidAmount;
  final int targetAmount;

  /// false — чужие деревья для общей карты города (обезличенные).
  final bool isMine;

  // Появляются только после подтверждения посадки исполнителем.
  final DateTime? plantedAt;
  final LatLng? location;
  final String? locationName;
  final String? plantedBy;
  final int photoCount;

  bool get isPlanted => status == TreeStatus.planted || status == TreeStatus.monitoring;
  bool get isGrowing => status == TreeStatus.growing;

  double get progress => targetAmount == 0 ? 1 : (paidAmount / targetAmount).clamp(0, 1).toDouble();
  GrowthStage get stage => GrowthStage.fromProgress(progress);

  /// «Листик» или код, если имени нет.
  String get displayName => (name == null || name!.trim().isEmpty) ? code : name!;

  Tree copyWith({
    TreeStatus? status,
    String? name,
    int? paidAmount,
    List<TreeEvent>? events,
    DateTime? plantedAt,
    LatLng? location,
    String? locationName,
    String? plantedBy,
    int? photoCount,
  }) =>
      Tree(
        id: id,
        code: code,
        speciesId: speciesId,
        orderId: orderId,
        status: status ?? this.status,
        orderedAt: orderedAt,
        events: events ?? this.events,
        name: name ?? this.name,
        paidAmount: paidAmount ?? this.paidAmount,
        targetAmount: targetAmount,
        isMine: isMine,
        plantedAt: plantedAt ?? this.plantedAt,
        location: location ?? this.location,
        locationName: locationName ?? this.locationName,
        plantedBy: plantedBy ?? this.plantedBy,
        photoCount: photoCount ?? this.photoCount,
      );
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Порог для прогресса (например 5 деревьев).
  final int target;
}

/// Достижение с вычисленным прогрессом для текущего пользователя.
class AchievementProgress {
  const AchievementProgress(this.achievement, this.current);
  final Achievement achievement;
  final int current;

  bool get earned => current >= achievement.target;
  double get ratio => (current / achievement.target).clamp(0, 1).toDouble();
}
