import 'package:admivida/business/features/add_sale/models/create_sale_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_provider.g.dart';

@riverpod
class Cart extends _$Cart {
  @override
  List<CreateSaleDetailInnerDto> build() {
    return []; // El carrito inicia vacío
  }

  void addItem(CreateSaleDetailInnerDto newItem) {
    final index = state.indexWhere(
      (item) => item.productVariantId == newItem.productVariantId && item.unitPrice == newItem.unitPrice && item.commentary == newItem.commentary,
    );

    if (index != -1) {
      final existingItem = state[index];
      final newQuantity = existingItem.quantity + newItem.quantity;
      final updatedItem = existingItem.copyWith(quantity: newQuantity, subtotal: newQuantity * existingItem.unitPrice);

      state = [...state.sublist(0, index), updatedItem, ...state.sublist(index + 1)];
    } else {
      state = [...state, newItem];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updateQuantity(String id, double newQuantity) {
    if (newQuantity <= 0) {
      removeItem(id);
      return;
    }

    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: newQuantity, subtotal: newQuantity * item.unitPrice);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  // Updates the unit price of a specific item in the cart
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
}

// 💡 Cambiamos CartTotalRef por la clase genérica Ref
@riverpod
double cartTotal(Ref ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
}

// 💡 Cambiamos CartItemCountRef por la clase genérica Ref
@riverpod
double cartItemCount(Ref ref) {
  final cartItems = ref.watch(cartProvider);
  return cartItems.fold(0.0, (sum, item) => sum + item.quantity);
}
