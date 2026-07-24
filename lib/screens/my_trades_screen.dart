import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trades_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';

class MyTradesScreen extends ConsumerStatefulWidget {
  final String? highlightRequestId;

  const MyTradesScreen({super.key, this.highlightRequestId});

  @override
  ConsumerState<MyTradesScreen> createState() => _MyTradesScreenState();
}

class _MyTradesScreenState extends ConsumerState<MyTradesScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _tradeKeys = {};
  bool _hasScrolledToHighlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tradesProvider.notifier).fetchUserTrades();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlightIfNeeded(List<TradeRequest> trades) {
    final requestId = widget.highlightRequestId;
    if (requestId == null || _hasScrolledToHighlight) return;

    final index = trades.indexWhere((t) => t.id == requestId);
    if (index < 0) return;

    _hasScrolledToHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _tradeKeys[requestId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleAction(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _showReviewDialog(TradeRequest trade) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rate your experience with ${trade.isSent ? trade.ownerName : trade.requesterName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => rating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dialogContext = context;
                final revieweeId =
                    trade.isSent ? trade.ownerId : trade.requesterId;
                final error = await ref.read(tradesProvider.notifier).submitReview(
                      requestId: trade.id,
                      revieweeId: revieweeId,
                      rating: rating,
                      comment: commentController.text.isEmpty
                          ? null
                          : commentController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (error != null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted — trust scores will update on refresh'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportIssueDialog(TradeRequest trade) {
    String? selectedCategory;
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select category',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                    DropdownMenuItem(value: 'stolen', child: Text('Stolen')),
                    DropdownMenuItem(value: 'no-show', child: Text('No-show')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Description',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe the issue',
                  ),
                  maxLines: 4,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  selectedCategory != null) {
                final dialogContext = context;
                final error =
                    await ref.read(tradesProvider.notifier).submitComplaint(
                          requestId: trade.id,
                          category: selectedCategory!,
                          description: descriptionController.text,
                        );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (error != null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Report submitted — trust scores will update on refresh'),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 120, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Container(height: 14, width: 200, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Container(height: 14, width: 140, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(height: 12, width: 80, color: Colors.grey.shade300),
                  const SizedBox(width: 8),
                  Container(height: 12, width: 80, color: Colors.grey.shade300),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tradesState = ref.watch(tradesProvider);
    final highlightId = widget.highlightRequestId;
    final currentLanguage = languageProvider.language ?? 'en';

    if (tradesState.status == TradesStatus.loaded && highlightId != null) {
      _scrollToHighlightIfNeeded(tradesState.trades);
    }

    ref.listen<TradesState>(tradesProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(tradesProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('trades_title', currentLanguage)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(tradesProvider.notifier).fetchUserTrades(),
          ),
        ],
      ),
      body: tradesState.status == TradesStatus.loading
          ? _buildTradesLoadingState()
          : tradesState.trades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'You have no active trade requests yet.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(tradesProvider.notifier).fetchUserTrades(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: tradesState.trades.length,
                    itemBuilder: (context, index) {
                      final trade = tradesState.trades[index];
                      final isHighlighted = trade.id == highlightId;
                      _tradeKeys.putIfAbsent(trade.id, GlobalKey.new);
                      return KeyedSubtree(
                        key: _tradeKeys[trade.id],
                        child: _TradeCard(
                          trade: trade,
                          isHighlighted: isHighlighted,
                          onAccept: () => _handleAction(() => ref
                              .read(tradesProvider.notifier)
                              .acceptRequest(trade.id)),
                          onReject: () => _handleAction(() => ref
                              .read(tradesProvider.notifier)
                              .rejectRequest(trade.id)),
                          onComplete: () => _handleAction(() => ref
                              .read(tradesProvider.notifier)
                              .completeRequest(trade.id)),
                          onReview: () => _showReviewDialog(trade),
                          onReportIssue: () => _showReportIssueDialog(trade),
                          currentLanguage: currentLanguage,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final TradeRequest trade;
  final bool isHighlighted;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onReview;
  final VoidCallback onReportIssue;
  final String currentLanguage;

  const _TradeCard({
    required this.trade,
    this.isHighlighted = false,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onReview,
    required this.onReportIssue,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = trade.status == 'completed';
    final isAccepted = trade.status == 'accepted';
    final isPending = trade.status == 'pending';
    final isSent = trade.isSent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isHighlighted ? Colors.green.shade50 : null,
      elevation: isHighlighted ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (trade.listingPhotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      trade.listingPhotoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.agriculture, color: Colors.green.shade700),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.listingTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trade.listingCategory,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isSent ? Icons.arrow_forward : Icons.arrow_back,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isSent
                                  ? 'To: ${trade.ownerName}'
                                  : 'From: ${trade.requesterName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: trade.status, currentLanguage: currentLanguage),
              ],
            ),
            const SizedBox(height: 12),

            // Owner actions on pending incoming requests
            if (!isSent && isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(AppStrings.t('trades_accept_button', currentLanguage)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(AppStrings.t('trades_reject_button', currentLanguage)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

            // Either participant can mark accepted trades as completed
            if (isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(AppStrings.t('trades_mark_completed_button', currentLanguage)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            // Review / complaint actions on completed trades
            if (isCompleted) ...[
              if (!trade.hasUserReviewed)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.star, size: 18),
                    label: Text(AppStrings.t('trades_leave_review_button', currentLanguage)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade800,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Review submitted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!trade.hasUserComplained)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReportIssue,
                    icon: const Icon(Icons.report, size: 18),
                    label: Text(AppStrings.t('trades_report_issue_button', currentLanguage)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                )
              else
                Text(
                  'Issue reported',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String currentLanguage;

  const _StatusChip({required this.status, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = AppStrings.t('trades_status_pending', currentLanguage);
        break;
      case 'accepted':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = AppStrings.t('trades_status_accepted', currentLanguage);
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        label = AppStrings.t('trades_status_rejected', currentLanguage);
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = AppStrings.t('trades_status_completed', currentLanguage);
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
