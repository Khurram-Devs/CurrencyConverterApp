class Currency {
  final String code;
  final String name;
  final String category; // 'fiat', 'crypto', or 'metal'

  Currency({required this.code, required this.name, required this.category});
}
