part of '../transactions_page.dart';

class TransactionSheet extends StatefulWidget {
  final TransactionWithJoins? data;
  final int? initialUserId;
  const TransactionSheet({this.data, this.initialUserId});
  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}
