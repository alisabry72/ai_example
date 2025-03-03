class Request {
  final String? quantity;
  final String? address;
  final String? collectionDate;
  final String? giftSelection;

  Request({
    this.quantity,
    this.address,
    this.collectionDate,
    this.giftSelection,
  });

  bool get isComplete =>
      quantity != null &&
      address != null &&
      collectionDate != null &&
      giftSelection != null;

  Request copyWith({
    String? quantity,
    String? address,
    String? collectionDate,
    String? giftSelection,
  }) {
    return Request(
      quantity: quantity ?? this.quantity,
      address: address ?? this.address,
      collectionDate: collectionDate ?? this.collectionDate,
      giftSelection: giftSelection ?? this.giftSelection,
    );
  }
}
