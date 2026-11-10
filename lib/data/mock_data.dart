import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Моковые данные прототипа. Бэка нет, всё живёт в памяти.
abstract final class MockData {
  static const almatyCenter = LatLng(43.2380, 76.9100);

  static const species = <TreeSpecies>[
    TreeSpecies(
      id: 'elm',
      name: 'Карагач',
      latinName: 'Ulmus pumila',
      shortDescription: 'Неприхотливый, хорошо переносит жару и городской воздух',
      description:
          'Классическое дерево алматинских улиц. Быстро растёт, даёт густую тень и легко переносит засуху и загазованность. Хороший выбор для дворов и вдоль дорог.',
      price: 6000,
      co2PerYear: 22,
      heightLabel: 'до 15 м',
      icon: Icons.park_rounded,
      tint: Color(0xFFC9D9C4),
      isPopular: true,
    ),
    TreeSpecies(
      id: 'spruce',
      name: 'Тянь-шаньская ель',
      latinName: 'Picea schrenkiana',
      shortDescription: 'Символ Заилийского Алатау, зелёная круглый год',
      description:
          'Эндемик гор Тянь-Шаня, которая украшает склоны вокруг Алматы. Вечнозелёная, очищает воздух зимой, когда городу это особенно нужно.',
      price: 8500,
      co2PerYear: 18,
      heightLabel: 'до 40 м',
      icon: Icons.forest_rounded,
      tint: Color(0xFFB9CDB8),
      isPopular: true,
    ),
    TreeSpecies(
      id: 'apple',
      name: 'Яблоня Сиверса',
      latinName: 'Malus sieversii',
      shortDescription: 'Дикий предок всех яблонь, родом из Алматы',
      description:
          'Та самая «алма», давшая имя городу. Весной цветёт белыми и розовыми цветами, а осенью даёт мелкие ароматные плоды. Редкий вид, который важно сохранять.',
      price: 7000,
      co2PerYear: 16,
      heightLabel: 'до 10 м',
      icon: Icons.local_florist_rounded,
      tint: Color(0xFFE9D8CF),
      isPopular: true,
    ),
    TreeSpecies(
      id: 'maple',
      name: 'Клён татарский',
      latinName: 'Acer tataricum',
      shortDescription: 'Компактный, красиво краснеет осенью',
      description:
          'Небольшое дерево, которое подходит для узких улиц и дворов. Устойчив к засухе, осенью листья становятся ярко-красными.',
      price: 6000,
      co2PerYear: 14,
      heightLabel: 'до 9 м',
      icon: Icons.eco_rounded,
      tint: Color(0xFFF1DDC8),
    ),
    TreeSpecies(
      id: 'oak',
      name: 'Дуб черешчатый',
      latinName: 'Quercus robur',
      shortDescription: 'Долгожитель, растёт сотни лет',
      description:
          'Мощное и долговечное дерево. Растёт медленнее остальных, но со временем становится одним из главных поглотителей CO₂ в парке.',
      price: 9000,
      co2PerYear: 25,
      heightLabel: 'до 30 м',
      icon: Icons.nature_rounded,
      tint: Color(0xFFD4D9B8),
    ),
    TreeSpecies(
      id: 'birch',
      name: 'Берёза повислая',
      latinName: 'Betula pendula',
      shortDescription: 'Светлая крона, быстро растёт',
      description:
          'Быстрорастущее дерево с лёгкой ажурной кроной. Хорошо приживается в парках и у водоёмов, создаёт мягкую рассеянную тень.',
      price: 6500,
      co2PerYear: 20,
      heightLabel: 'до 25 м',
      icon: Icons.grass_rounded,
      tint: Color(0xFFDDE6D3),
    ),
  ];

  static const includes = <PlantingIncludes>[
    PlantingIncludes('Саженец из питомника', Icons.spa_outlined),
    PlantingIncludes('Посадка исполнителем', Icons.handyman_outlined),
    PlantingIncludes('Доставка на место', Icons.local_shipping_outlined),
    PlantingIncludes('Уход и полив первый год', Icons.water_drop_outlined),
    PlantingIncludes('Цифровое отслеживание', Icons.qr_code_2_rounded),
  ];

  /// Зоны озеленения, из которых исполнитель выбирает место посадки.
  static const plantingZones = <({String name, LatLng point})>[
    (name: 'Парк им. 28 гвардейцев-панфиловцев', point: LatLng(43.2587, 76.9535)),
    (name: 'Ботанический сад', point: LatLng(43.2240, 76.9120)),
    (name: 'Парк Первого Президента', point: LatLng(43.1890, 76.8860)),
    (name: 'Терренкур вдоль реки Есентай', point: LatLng(43.2170, 76.9280)),
    (name: 'Центральный парк им. Горького', point: LatLng(43.2600, 76.9690)),
    (name: 'Озеро Сайран', point: LatLng(43.2380, 76.8670)),
    (name: 'Парк «Арбат» на Жибек Жолы', point: LatLng(43.2620, 76.9440)),
    (name: 'Бульвар Аль-Фараби', point: LatLng(43.2050, 76.9000)),
  ];

  static const planterName = 'Ерлан Сапаров';

  static const achievements = <Achievement>[
    Achievement(
      id: 'first_sprout',
      title: 'Первый росток',
      description: 'Посадите первое дерево',
      icon: Icons.spa_rounded,
      target: 1,
    ),
    Achievement(
      id: 'small_grove',
      title: 'Маленькая роща',
      description: 'Посадите 5 деревьев',
      icon: Icons.park_rounded,
      target: 5,
    ),
    Achievement(
      id: 'forester',
      title: 'Лесник',
      description: 'Посадите 10 деревьев',
      icon: Icons.forest_rounded,
      target: 10,
    ),
    Achievement(
      id: 'variety',
      title: 'Разнообразие',
      description: 'Посадите 3 разных вида',
      icon: Icons.diversity_2_rounded,
      target: 3,
    ),
    Achievement(
      id: 'pioneer',
      title: 'Первопроходец',
      description: 'Один из первых 100 участников',
      icon: Icons.flag_rounded,
      target: 1,
    ),
    Achievement(
      id: 'caretaker',
      title: 'Заботливый',
      description: 'Получите 3 обновления об уходе',
      icon: Icons.water_drop_rounded,
      target: 3,
    ),
  ];

  /// Обезличенные посадки других жителей для общей карты.
  static List<Tree> cityTrees() {
    final points = <LatLng>[
      const LatLng(43.2595, 76.9512), const LatLng(43.2571, 76.9560), const LatLng(43.2602, 76.9548),
      const LatLng(43.2251, 76.9101), const LatLng(43.2229, 76.9142), const LatLng(43.2262, 76.9133),
      const LatLng(43.1902, 76.8841), const LatLng(43.1875, 76.8879), const LatLng(43.1911, 76.8890),
      const LatLng(43.2161, 76.9265), const LatLng(43.2182, 76.9301), const LatLng(43.2610, 76.9672),
      const LatLng(43.2588, 76.9711), const LatLng(43.2371, 76.8651), const LatLng(43.2393, 76.8692),
      const LatLng(43.2628, 76.9425), const LatLng(43.2041, 76.8977), const LatLng(43.2063, 76.9021),
      const LatLng(43.2455, 76.9280), const LatLng(43.2330, 76.9550), const LatLng(43.2480, 76.8890),
      const LatLng(43.2290, 76.8780),
    ];
    return [
      for (var i = 0; i < points.length; i++)
        Tree(
          id: 'city_$i',
          code: 'PT-ALM-${(100 + i).toString().padLeft(6, '0')}',
          speciesId: species[i % species.length].id,
          orderId: 'city',
          status: i.isEven ? TreeStatus.monitoring : TreeStatus.planted,
          paidAmount: 6000,
          targetAmount: 6000,
          orderedAt: DateTime(2026, 8, 1).add(Duration(days: i)),
          plantedAt: DateTime(2026, 9, 1).add(Duration(days: i * 2)),
          location: points[i],
          events: const [],
          isMine: false,
        ),
    ];
  }

  /// Демо-аккаунт для входа: три дерева в разных статусах.
  static const demoUser = (name: 'Амалия Огай', email: 'ogay.a@gmail.com');

  static ({List<Order> orders, List<Tree> trees}) demoForest() {
    final o1 = DateTime(2026, 9, 3, 14, 20);
    final o2 = DateTime(2026, 10, 28, 11, 5);
    final o3 = DateTime(2026, 11, 2, 9, 40);
    final orders = [
      Order(
        id: 'o1',
        number: 1012,
        speciesId: 'elm',
        quantity: 2,
        unitPrice: 6000,
        createdAt: o1,
        status: OrderStatus.completed,
        treeIds: const ['t1', 't2'],
      ),
      Order(
        id: 'o3',
        number: 1063,
        speciesId: 'elm',
        quantity: 1,
        unitPrice: 6000,
        createdAt: o3,
        status: OrderStatus.confirmed,
        treeIds: const ['t4'],
        paymentMode: PaymentMode.installments,
        installment: 2000,
      ),
      Order(
        id: 'o2',
        number: 1047,
        speciesId: 'spruce',
        quantity: 1,
        unitPrice: 8500,
        createdAt: o2,
        status: OrderStatus.confirmed,
        treeIds: const ['t3'],
      ),
    ];
    final zone0 = plantingZones[0];
    final trees = [
      // Копится взносами — «Листик» с главного экрана дизайна.
      Tree(
        id: 't4',
        code: 'PT-ALM-000127',
        name: 'Листик',
        speciesId: 'elm',
        orderId: 'o3',
        status: TreeStatus.growing,
        orderedAt: o3,
        paidAmount: 3840,
        targetAmount: 6000,
        events: [
          TreeEvent(type: TreeEventType.ordered, date: o3, title: 'Заказ оформлен'),
          TreeEvent(type: TreeEventType.topUp, date: DateTime(2026, 11, 2), title: 'Взнос 2 000 ₸'),
          TreeEvent(type: TreeEventType.topUp, date: DateTime(2026, 11, 8), title: 'Взнос 1 840 ₸'),
        ],
      ),
      Tree(
        id: 't1',
        code: 'PT-ALM-000121',
        name: 'Тянь-Шань',
        paidAmount: 6000,
        targetAmount: 6000,
        speciesId: 'elm',
        orderId: 'o1',
        status: TreeStatus.monitoring,
        orderedAt: o1,
        plantedAt: DateTime(2026, 9, 14),
        location: zone0.point,
        locationName: zone0.name,
        plantedBy: planterName,
        photoCount: 3,
        events: [
          TreeEvent(type: TreeEventType.ordered, date: o1, title: 'Заказ оформлен'),
          TreeEvent(
            type: TreeEventType.planted,
            date: DateTime(2026, 9, 14),
            title: 'Дерево посажено',
            note: 'Саженец 1,8 м, установлена опора',
            author: planterName,
          ),
          TreeEvent(
            type: TreeEventType.watered,
            date: DateTime(2026, 10, 2),
            title: 'Полив',
            author: planterName,
          ),
          TreeEvent(
            type: TreeEventType.checked,
            date: DateTime(2026, 10, 30),
            title: 'Плановый осмотр',
            note: 'Прижилось, появились новые побеги',
            author: planterName,
          ),
        ],
      ),
      Tree(
        id: 't2',
        code: 'PT-ALM-000122',
        name: 'Алма',
        paidAmount: 6000,
        targetAmount: 6000,
        speciesId: 'elm',
        orderId: 'o1',
        status: TreeStatus.planted,
        orderedAt: o1,
        plantedAt: DateTime(2026, 9, 14),
        location: const LatLng(43.2579, 76.9551),
        locationName: zone0.name,
        plantedBy: planterName,
        photoCount: 1,
        events: [
          TreeEvent(type: TreeEventType.ordered, date: o1, title: 'Заказ оформлен'),
          TreeEvent(
            type: TreeEventType.planted,
            date: DateTime(2026, 9, 14),
            title: 'Дерево посажено',
            note: 'Посажено рядом с аллеей',
            author: planterName,
          ),
        ],
      ),
      Tree(
        id: 't3',
        code: 'PT-ALM-000123',
        name: 'Шёпот',
        paidAmount: 8500,
        targetAmount: 8500,
        speciesId: 'spruce',
        orderId: 'o2',
        status: TreeStatus.awaitingPlanting,
        orderedAt: o2,
        events: [
          TreeEvent(type: TreeEventType.ordered, date: o2, title: 'Заказ оформлен'),
        ],
      ),
    ];
    return (orders: orders, trees: trees);
  }
}
