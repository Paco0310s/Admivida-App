import 'dart:async';
import 'package:admivida/business/features/add_sale/cart/cart_service.dart';
import 'package:admivida/business/features/add_sale/models/business_client_model.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  List<CreateSaleDetailInnerDto> build() {
    return []; // The cart starts empty
  }

  double currentVariantQuantity(String productVariantId, {String? excludeItemId}) {
    double total = 0.0;
    for (final item in state) {
      if (item.productVariantId == productVariantId && item.id != excludeItemId) {
        total += item.quantity;
      }
    }
    return total;
  }

  bool addItem(CreateSaleDetailInnerDto newItem) {
    final index = state.indexWhere(
      (item) => item.productVariantId == newItem.productVariantId && item.unitPrice == newItem.unitPrice && item.commentary == newItem.commentary,
    );

    if (!newItem.isCommonProduct) {
      final double? stockLimit = newItem.availableStock ??
          state.where((i) => i.productVariantId == newItem.productVariantId && i.availableStock != null).map((i) => i.availableStock).firstOrNull;
      if (stockLimit != null) {
        final alreadyInCart = currentVariantQuantity(newItem.productVariantId);
        if (alreadyInCart + newItem.quantity > stockLimit + 1e-6) {
          return false;
        }
      }
    }

    if (index != -1) {
      final existingItem = state[index];
      final newQuantity = existingItem.quantity + newItem.quantity;
      final updatedItem = existingItem.copyWith(
        quantity: newQuantity,
        subtotal: newQuantity * existingItem.unitPrice,
        availableStock: newItem.availableStock ?? existingItem.availableStock,
      );

      state = [...state.sublist(0, index), updatedItem, ...state.sublist(index + 1)];
    } else {
      state = [...state, newItem];
    }
    return true;
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  bool updateQuantity(String id, double newQuantity) {
    if (newQuantity <= 0) {
      removeItem(id);
      return true;
    }

    final targetIndex = state.indexWhere((item) => item.id == id);
    if (targetIndex == -1) return false;
    final target = state[targetIndex];

    if (!target.isCommonProduct && target.availableStock != null) {
      final otherQty = currentVariantQuantity(target.productVariantId, excludeItemId: id);
      if (otherQty + newQuantity > target.availableStock! + 1e-6) {
        return false;
      }
    }

    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: newQuantity, subtotal: newQuantity * item.unitPrice);
      }
      return item;
    }).toList();
    return true;
  }

  void clearCart() {
    state = [];
  }

  void replaceCart(List<CreateSaleDetailInnerDto> items) {
    state = List<CreateSaleDetailInnerDto>.from(items);
  }

  /// Updates the unit price of a specific item in the cart
  void updateUnitPrice(String id, double newPrice) {
    if (newPrice < 0) return;

    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(
          unitPrice: newPrice,
          priceType: 'CUSTOM', // Automatically set as custom price
          subtotal: newPrice * item.quantity,
        );
      }
      return item;
    }).toList();
  }

  /// Updates the isPaid flag of a specific item in the cart
  void updateIsPaid(String id, bool isPaid) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isPaid: isPaid);
      }
      return item;
    }).toList();
  }
}

@riverpod
double cartTotal(Ref ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
}

@riverpod
double cartItemCount(Ref ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0.0, (sum, item) => sum + item.quantity);
}

/// Provider to fetch the list of clients for the dropdown.
@riverpod
Future<List<BusinessClientModel>> businessClients(Ref ref, String businessId) async {
  final result = await CartService.getClients(businessId);

  return result.when((failure) => throw failure, (clients) => clients);
}

enum PosCartShortcutAction {
  cycleCartSelection,
  editQuantity,
  editPrice,
  selectClient,
  parkSale,
  focusDiscount,
  showHeldCarts,
  cyclePaymentMethod,
  checkout,
}

class PosShortcutBus {
  static final StreamController<PosCartShortcutAction> _controller = StreamController<PosCartShortcutAction>.broadcast();

  static Stream<PosCartShortcutAction> get stream => _controller.stream;

  static void emit(PosCartShortcutAction action) {
    if (!_controller.isClosed) {
      _controller.add(action);
    }
  }
}
