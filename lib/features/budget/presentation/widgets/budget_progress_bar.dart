import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double progress;
  final bool isExceeded;
  final bool isApproaching;

  const BudgetProgressBar({
    super.key,
    required this.progress,
    required this.isExceeded,
    required this.isApproaching,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            minHeight: 8,
          ),
        ),
        if (isExceeded || isApproaching) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isExceeded ? Icons.warning : Icons.info,
                size: 12,
                color: _getProgressColor(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isExceeded 
                    ? 'Budget exceeded by ${(progress - 100).toStringAsFixed(1)}%'
                    : 'Approaching budget limit',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getProgressColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getProgressColor() {
    if (isExceeded) {
      return Colors.red;
    } else if (isApproaching) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
} 