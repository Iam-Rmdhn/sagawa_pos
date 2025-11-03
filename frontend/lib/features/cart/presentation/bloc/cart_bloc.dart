import 'package:bloc/bloc.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../core/utils/logger.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final Map<String, CartItem> _items = {};

  CartBloc() : super(CartInitial()) {
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartQuantityEvent>(_onUpdateQuantity);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    if (_items.containsKey(event.productId)) {
      // Update quantity if item exists
      final existingItem = _items[event.productId]!;
      _items[event.productId] = CartItem(
        productId: existingItem.productId,
        name: existingItem.name,
        quantity: existingItem.quantity + event.quantity,
        price: existingItem.price,
        subtotal: existingItem.price * (existingItem.quantity + event.quantity),
      );
    } else {
      // Add new item
      _items[event.productId] = CartItem(
        productId: event.productId,
        name: event.name,
        quantity: event.quantity,
        price: event.price,
        subtotal: event.price * event.quantity,
      );
    }

    AppLogger.info('Added to cart: ${event.name} x${event.quantity}');
    _emitLoadedState(emit);
  }

  void _onUpdateQuantity(
    UpdateCartQuantityEvent event,
    Emitter<CartState> emit,
  ) {
    if (event.quantity <= 0) {
      _items.remove(event.productId);
      AppLogger.info('Removed item from cart: ${event.productId}');
    } else if (_items.containsKey(event.productId)) {
      final item = _items[event.productId]!;
      _items[event.productId] = CartItem(
        productId: item.productId,
        name: item.name,
        quantity: event.quantity,
        price: item.price,
        subtotal: item.price * event.quantity,
      );
      AppLogger.info(
        'Updated quantity: ${event.productId} = ${event.quantity}',
      );
    }

    _emitLoadedState(emit);
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    _items.remove(event.productId);
    AppLogger.info('Removed from cart: ${event.productId}');
    _emitLoadedState(emit);
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    _items.clear();
    AppLogger.info('Cart cleared');
    _emitLoadedState(emit);
  }

  void _emitLoadedState(Emitter<CartState> emit) {
    final totalAmount = _items.values.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final itemCount = _items.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    emit(
      CartLoaded(
        items: Map.from(_items),
        totalAmount: totalAmount,
        itemCount: itemCount,
      ),
    );
  }
}
