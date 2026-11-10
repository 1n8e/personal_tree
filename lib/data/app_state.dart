import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'mock_data.dart';
import 'models.dart';

/// Эко-баллы: +20 за регистрацию, +100 за каждое подтверждённое дерево.
const registrationPoints = 20;
const pointsPerPlantedTree = 100;

/// Всё состояние прототипа в одном месте. Бэкенда нет.
class AppState {
  const AppState({
    this.hasSeenOnboarding = false,
    this.user,
    this.orders = const [],
    this.trees = const [],
    this.cityTrees = const [],
    this.planterMode = false,
    this.nextOrderNumber = 1100,
    this.nextTreeNumber = 124,
  });

  final bool hasSeenOnboarding;
  final UserProfile? user;
  final List<Order> orders;

  /// Деревья текущего пользователя.
  final List<Tree> trees;

  /// Обезличенные посадки других жителей.
  final List<Tree> cityTrees;

  /// Демо-переключатель «Режим исполнителя».
  final bool planterMode;
  final int nextOrderNumber;
  final int nextTreeNumber;

  bool get isLoggedIn => user != null;

  List<Tree> get plantedTrees => trees.where((t) => t.isPlanted).toList();
  List<Tree> get awaitingTrees => trees.where((t) => t.status == TreeStatus.awaitingPlanting).toList();
  List<Tree> get growingTrees => trees.where((t) => t.isGrowing).toList();

  int get ecoPoints => isLoggedIn ? registrationPoints + plantedTrees.length * pointsPerPlantedTree : 0;

  /// Примерное поглощение CO₂ посаженными деревьями, кг/год.
  int get co2PerYear => plantedTrees.fold(0, (sum, t) => sum + speciesById(t.speciesId).co2PerYear);

  /// Всего посажено в городе: чужие + свои подтверждённые.
  int get cityPlantedCount => cityTrees.length + plantedTrees.length + 1240;

  List<AchievementProgress> get achievements {
    final planted = plantedTrees;
    final kinds = planted.map((t) => t.speciesId).toSet().length;
    final careEvents = trees
        .expand((t) => t.events)
        .where((e) => e.type == TreeEventType.watered || e.type == TreeEventType.checked)
        .length;
    int current(Achievement a) => switch (a.id) {
          'first_sprout' || 'small_grove' || 'forester' => planted.length,
          'variety' => kinds,
          'pioneer' => isLoggedIn ? 1 : 0,
          'caretaker' => careEvents,
          _ => 0,
        };
    return [for (final a in MockData.achievements) AchievementProgress(a, current(a))];
  }

  Tree? treeById(String id) {
    for (final t in [...trees, ...cityTrees]) {
      if (t.id == id) return t;
    }
    return null;
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  AppState copyWith({
    bool? hasSeenOnboarding,
    UserProfile? user,
    bool clearUser = false,
    List<Order>? orders,
    List<Tree>? trees,
    List<Tree>? cityTrees,
    bool? planterMode,
    int? nextOrderNumber,
    int? nextTreeNumber,
  }) =>
      AppState(
        hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
        user: clearUser ? null : (user ?? this.user),
        orders: orders ?? this.orders,
        trees: trees ?? this.trees,
        cityTrees: cityTrees ?? this.cityTrees,
        planterMode: planterMode ?? this.planterMode,
        nextOrderNumber: nextOrderNumber ?? this.nextOrderNumber,
        nextTreeNumber: nextTreeNumber ?? this.nextTreeNumber,
      );
}

TreeSpecies speciesById(String id) => MockData.species.firstWhere((s) => s.id == id);

class AppController extends Notifier<AppState> {
  @override
  AppState build() => AppState(cityTrees: MockData.cityTrees());

  void completeOnboarding() => state = state.copyWith(hasSeenOnboarding: true);

  /// Вход в демо-аккаунт с уже посаженными деревьями.
  void loginDemo() {
    final forest = MockData.demoForest();
    state = state.copyWith(
      hasSeenOnboarding: true,
      user: UserProfile(
        id: 'u_demo',
        name: MockData.demoUser.name,
        email: MockData.demoUser.email,
        registeredAt: DateTime(2026, 9, 1),
      ),
      orders: forest.orders,
      trees: forest.trees,
    );
  }

  /// Регистрация нового пользователя: пустой лес, +20 баллов.
  void register({required String name, required String email}) {
    state = state.copyWith(
      hasSeenOnboarding: true,
      user: UserProfile(id: 'u_new', name: name, email: email, registeredAt: DateTime.now()),
      orders: const [],
      trees: const [],
    );
  }

  void logout() => state = state.copyWith(clearUser: true, orders: const [], trees: const [], planterMode: false);

  /// Оформляет заказ. Оплата будет на следующем этапе, поэтому заказ сразу «Подтверждён».
  /// На каждую единицу создаётся отдельное дерево.
  /// «Сразу» — дерево сразу «Ожидает посадки»; «Копить» — «Растёт» с первым взносом.
  Order placeOrder({
    required String speciesId,
    required int quantity,
    String? name,
    PaymentMode mode = PaymentMode.full,
    int? installment,
  }) {
    final now = DateTime.now();
    final species = speciesById(speciesId);
    final orderId = 'o${state.nextOrderNumber}';
    final saving = mode == PaymentMode.installments;
    final firstPayment = saving ? (installment ?? species.price).clamp(0, species.price) : species.price;
    final trimmed = name?.trim();
    final newTrees = [
      for (var i = 0; i < quantity; i++)
        Tree(
          id: 't${state.nextTreeNumber + i}',
          code: 'PT-ALM-${(state.nextTreeNumber + i).toString().padLeft(6, '0')}',
          name: trimmed == null || trimmed.isEmpty ? null : (quantity > 1 ? '$trimmed ${i + 1}' : trimmed),
          speciesId: speciesId,
          orderId: orderId,
          status: saving && firstPayment < species.price ? TreeStatus.growing : TreeStatus.awaitingPlanting,
          orderedAt: now,
          paidAmount: firstPayment,
          targetAmount: species.price,
          events: [TreeEvent(type: TreeEventType.ordered, date: now, title: 'Заказ оформлен')],
        ),
    ];
    final order = Order(
      id: orderId,
      number: state.nextOrderNumber,
      speciesId: speciesId,
      quantity: quantity,
      unitPrice: species.price,
      createdAt: now,
      status: OrderStatus.confirmed,
      treeIds: [for (final t in newTrees) t.id],
      paymentMode: mode,
      installment: saving ? installment : null,
    );
    state = state.copyWith(
      orders: [order, ...state.orders],
      trees: [...newTrees, ...state.trees],
      nextOrderNumber: state.nextOrderNumber + 1,
      nextTreeNumber: state.nextTreeNumber + quantity,
    );
    return order;
  }

  /// Взнос в копилку дерева. На 100% дерево «выросло» и уходит исполнителю.
  void topUp({required String treeId, required int amount}) {
    final now = DateTime.now();
    _updateTree(treeId, (t) {
      if (!t.isGrowing) return t;
      final paid = (t.paidAmount + amount).clamp(0, t.targetAmount);
      final grown = paid >= t.targetAmount;
      return t.copyWith(
        paidAmount: paid,
        status: grown ? TreeStatus.awaitingPlanting : TreeStatus.growing,
        events: [
          ...t.events,
          TreeEvent(type: TreeEventType.topUp, date: now, title: 'Взнос ${paid - t.paidAmount} ₸'),
          if (grown) TreeEvent(type: TreeEventType.grown, date: now, title: 'Дерево выращено до 100%'),
        ],
      );
    });
  }

  void renameTree({required String treeId, required String name}) =>
      _updateTree(treeId, (t) => t.copyWith(name: name.trim()));

  void setPlanterMode(bool value) => state = state.copyWith(planterMode: value);

  /// Исполнитель подтверждает посадку: фото + геоточка обязательны.
  /// Только после этого у дерева появляются дата, место и начисляются баллы.
  void confirmPlanting({required String treeId, required int zoneIndex, String? note}) {
    final zone = MockData.plantingZones[zoneIndex];
    final now = DateTime.now();
    // Небольшой сдвиг, чтобы маркеры одной зоны не накладывались.
    final jitter = (state.trees.indexWhere((t) => t.id == treeId) % 5) * 0.0006;
    _updateTree(
      treeId,
      (t) => t.copyWith(
        status: TreeStatus.planted,
        plantedAt: now,
        location: LatLng(zone.point.latitude + jitter, zone.point.longitude - jitter),
        locationName: zone.name,
        plantedBy: MockData.planterName,
        photoCount: 1,
        events: [
          ...t.events,
          TreeEvent(
            type: TreeEventType.planted,
            date: now,
            title: 'Дерево посажено',
            note: note,
            author: MockData.planterName,
          ),
        ],
      ),
    );
    _syncOrderStatuses();
  }

  /// Исполнитель добавляет запись ухода: дерево переходит в «На мониторинге».
  void addCareUpdate({required String treeId, required TreeEventType type, String? note}) {
    final now = DateTime.now();
    _updateTree(
      treeId,
      (t) => t.copyWith(
        status: TreeStatus.monitoring,
        photoCount: t.photoCount + 1,
        events: [
          ...t.events,
          TreeEvent(
            type: type,
            date: now,
            title: type == TreeEventType.watered ? 'Полив' : 'Плановый осмотр',
            note: note,
            author: MockData.planterName,
          ),
        ],
      ),
    );
  }

  void _updateTree(String id, Tree Function(Tree) update) {
    state = state.copyWith(trees: [for (final t in state.trees) t.id == id ? update(t) : t]);
  }

  void _syncOrderStatuses() {
    final byId = {for (final t in state.trees) t.id: t};
    state = state.copyWith(
      orders: [
        for (final o in state.orders)
          o.treeIds.every((id) => byId[id]?.isPlanted ?? false) ? o.copyWith(status: OrderStatus.completed) : o,
      ],
    );
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(AppController.new);
