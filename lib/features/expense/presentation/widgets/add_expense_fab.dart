import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../core/constants/app_constants.dart';

class AddExpenseFAB extends StatelessWidget {
  const AddExpenseFAB({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformWidgets.isIOS) {
      return CupertinoButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-expense');
        },
        padding: EdgeInsets.zero,
        child: Container(
          width: AppConstants.height56,
          height: AppConstants.height56,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.shadowL,
          ),
          child: const Icon(
            CupertinoIcons.add,
            color: CupertinoColors.white,
            size: 28,
          ),
        ),
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-expense');
        },
        backgroundColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
  }
}
