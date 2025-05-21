enum ChatAvailability {
  openToChat,
  requestOnly,
  doNotDisturb,
}

extension ChatAvailabilityExtension on ChatAvailability {
  String toJson() {
    return name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
  }

  static ChatAvailability fromJson(String jsonValue) {
    return ChatAvailability.values.firstWhere(
      (e) => e.toJson() == jsonValue,
      orElse: () => throw ArgumentError('Unknown ChatAvailability value: $jsonValue'),
    );
  }
}

enum ChatRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

// For ChatRequestStatus, the direct .name conversion to string and Enum.values.byName(String)
// or a simple switch case for fromJson would work if the backend sends exact enum names.
// If the backend sends snake_case, a similar extension method as above would be needed.
// For now, we'll assume direct mapping for ChatRequestStatus for simplicity,
// as the backend schema just lists the enum values.