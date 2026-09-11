import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CommissionPaymentScreen extends ConsumerStatefulWidget {
  const CommissionPaymentScreen({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<CommissionPaymentScreen> createState() => _CommissionPaymentScreenState();
}

class _CommissionPaymentScreenState extends ConsumerState<CommissionPaymentScreen> {
  String? _selectedSellerId;
  bool _isSubmitting = false;

  // Local state for the products
  List<PendingCommissionItem> _pendingItems = [];

  // Maps to track which items are selected and their editable text controllers
  final Map<String, bool> _selectedCheckboxes = {};
  final Map<String, TextEditingController> _itemControllers = {};

  // Controller for the grand total
  final TextEditingController _totalController = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _totalController.dispose();
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Calculates the total by summing only the selected items
  void _calculateTotal() {
    double total = 0.0;
    for (final item in _pendingItems) {
      if (_selectedCheckboxes[item.saleDetailId] == true) {
        final textValue = _itemControllers[item.saleDetailId]?.text ?? '0';
        total += double.tryParse(textValue) ?? 0.0;
      }
    }
    // Update the total textfield, but allow manual edits
    _totalController.text = total.toStringAsFixed(2);
  }

  /// Safely initializes controllers when new data arrives from the provider
  void _initializeItems(List<PendingCommissionItem> items) {
    if (!mounted) return;

    setState(() {
      _pendingItems = items;
      _selectedCheckboxes.clear();

      // Dispose old controllers
      for (final controller in _itemControllers.values) {
        controller.dispose();
      }
      _itemControllers.clear();

      for (final item in items) {
        _selectedCheckboxes[item.saleDetailId] = false; // Unselected by default

        final controller = TextEditingController(text: item.commission.toStringAsFixed(2));
        controller.addListener(_calculateTotal);
        _itemControllers[item.saleDetailId] = controller;
      }
      _calculateTotal(); // Reset the total
    });
  }

  /// Handles the POST request to pay commissions
  Future<void> _submitPayment() async {
    final selectedDetails = _pendingItems.where((item) => _selectedCheckboxes[item.saleDetailId] == true).map((item) => item.saleDetailId).toList();

    if (selectedDetails.isEmpty) {
      SnackbarUtil.showError(context, 'Please select at least one product to pay.');
      return;
    }

    final double finalTotal = double.tryParse(_totalController.text) ?? 0.0;
    if (finalTotal <= 0) {
      SnackbarUtil.showError(context, 'The total amount must be greater than 0.');
      return;
    }

    if (_selectedSellerId == null) return;

    setState(() => _isSubmitting = true);

    // // Call the POST provider
    // final success = await ref.read(commissionPaymentControllerProvider.notifier).payCommissions(
    //   businessId: widget.businessId,
    //   sellerUserId: _selectedSellerId!,
    //   saleDetailIds: selectedDetails,
    //   totalAmountPaid: finalTotal,
    // );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // if (success) {
    SnackbarUtil.showSuccess(context, 'Commission payment registered successfully.');
    // Optionally reset the view or pop the screen
    // NavigationService.pop(context);
    // } else {
    //   SnackbarUtil.showError(context, 'Failed to register the payment. Please try again.');
    // }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Sellers for the Dropdown
    final sellersAsync = ref.watch(businessSellersProvider(widget.businessId));

    // 2. Fetch Pending Items if a seller is selected
    final pendingProvider = _selectedSellerId != null ? pendingCommissionsProvider(businessId: widget.businessId, sellerId: _selectedSellerId!) : null;

    final pendingAsync = pendingProvider != null ? ref.watch(pendingProvider) : const AsyncValue.data(<PendingCommissionItem>[]);

    // 3. Listen to the pending items safely to initialize text controllers
    if (pendingProvider != null) {
      ref.listen<AsyncValue<List<PendingCommissionItem>>>(pendingProvider, (previous, next) {
        next.whenData((items) => _initializeItems(items));
      });
    }

    return AppScaffold(
      title: 'Commission Payments',
      appBar: AppBar(
        title: const AppText('Commission Payments', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(sellersAsync, pendingAsync),
      tablet: _buildContent(sellersAsync, pendingAsync),
      desktop: _buildContent(sellersAsync, pendingAsync),
      marginDesktop: 160,
    );
  }

  Widget _buildContent(AsyncValue<List<BusinessStaffModel>> sellersAsync, AsyncValue<List<PendingCommissionItem>> pendingAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSellerSelector(sellersAsync),
          const Gap(16),

          if (_selectedSellerId != null) ...[_buildPendingList(pendingAsync), const Gap(16), _buildSummaryCard()],
        ],
      ),
    );
  }

  /// Renders the Dropdown to pick the seller/admin
  Widget _buildSellerSelector(AsyncValue<List<BusinessStaffModel>> sellersAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Select Staff Member', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          sellersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading staff: $err'),
            data: (sellers) {
              if (sellers.isEmpty) {
                return const Text('No active sellers found for this business.');
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                hint: const Text('Choose a seller...'),
                initialValue: _selectedSellerId,
                items: sellers.map((seller) {
                  return DropdownMenuItem<String>(value: seller.userId, child: Text(seller.fullName));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSellerId = val;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Renders the list of pending items for the selected seller
  Widget _buildPendingList(AsyncValue<List<PendingCommissionItem>> pendingAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Pending Products', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Text('Error loading pending items: $err'),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No pending commissions for this user.')),
                );
              }
              return Column(children: _pendingItems.map((item) => _buildCommissionItem(item)).toList());
            },
          ),
        ],
      ),
    );
  }

  /// Renders a single row with checkbox and textfield
  Widget _buildCommissionItem(PendingCommissionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: _selectedCheckboxes[item.saleDetailId] ?? false,
            activeColor: AppColors.kPrimaryColor,
            onChanged: (val) {
              setState(() {
                _selectedCheckboxes[item.saleDetailId] = val ?? false;
                _calculateTotal();
              });
            },
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.productName, fontWeight: FontWeight.w600, fontSize: 14),
                AppText('${item.quantity} pzas - Sale: ${item.soldAt.day}/${item.soldAt.month}/${item.soldAt.year}', color: Colors.grey, fontSize: 12),
              ],
            ),
          ),
          const Gap(8),
          Expanded(
            flex: 1,
            child: AppTextField(
              text: '', // No label to save space
              hintText: '0.00',
              controller: _itemControllers[item.saleDetailId],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the bottom card with total and submit button
  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Payment Summary', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          AppTextField(
            text: 'Total to Pay',
            hintText: '0.00',
            controller: _totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Register Payment', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
