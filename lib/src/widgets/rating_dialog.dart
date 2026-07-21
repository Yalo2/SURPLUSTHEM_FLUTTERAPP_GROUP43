import 'package:flutter/material.dart';
import '../services/claim_service.dart';

class RatingDialog extends StatefulWidget {
  final String claimId;

  const RatingDialog({super.key, required this.claimId});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final ClaimService _claimService = ClaimService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Recipient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How was your experience?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
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
            await _claimService.rateRecipient(widget.claimId, _rating);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thank you for your rating!')),
            );
          },
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }
}
