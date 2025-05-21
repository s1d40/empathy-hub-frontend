/// Defines the type of vote that can be cast.
enum VoteType {
  upvote,
  downvote,
}

extension VoteTypeExtension on VoteType {
  /// Returns the string value expected by the backend.
  String get value {
    switch (this) {
      case VoteType.upvote:
        return 'upvote';
      case VoteType.downvote:
        return 'downvote';
    }
  }
}

/// Defines the status of a report.
/// Corresponds to ReportStatusEnum in the backend.
enum ReportStatus {
  pending,
  reviewedActionTaken,
  reviewedNoAction,
  dismissed,
}

extension ReportStatusExtension on ReportStatus {
  /// Returns the string value expected by the backend.
  String get backendValue {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewedActionTaken:
        return 'reviewed_action_taken';
      case ReportStatus.reviewedNoAction:
        return 'reviewed_no_action';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }
}

/// Defines the type of item being reported.
/// Corresponds to ReportedItemTypeEnum in the backend.
enum ReportedItemType {
  user,
  post,
  comment,
}

extension ReportedItemTypeExtension on ReportedItemType {
  /// Returns the string value expected by the backend.
  String get backendValue {
    switch (this) {
      case ReportedItemType.user:
        return 'user';
      case ReportedItemType.post:
        return 'post';
      case ReportedItemType.comment:
        return 'comment';
    }
  }
}

/// Defines the type of relationship between users (e.g., mute, block).
/// Corresponds to RelationshipTypeEnum in the backend.
enum RelationshipType {
  mute,
  block,
}

extension RelationshipTypeExtension on RelationshipType {
  /// Returns the string value expected by the backend.
  String get backendValue {
    switch (this) {
      case RelationshipType.mute:
        return 'mute';
      case RelationshipType.block:
        return 'block';
    }
  }
}

/// Defines common pronoun sets.
/// Your backend `User` model has `pronouns = Column(String, nullable=True)`.
/// This enum helps provide a structured way to select them, but the actual
/// value sent to the backend will be a string.
enum Pronouns {
  heHim,
  sheHer,
  theyThem,
  zeZir,
  askMe,
  // 'other' could imply a free-text field elsewhere if needed
}

extension PronounsExtension on Pronouns {
  /// Returns a display-friendly string and potentially the value for the backend.
  String get displayValue {
    switch (this) {
      case Pronouns.heHim:
        return 'He/Him';
      case Pronouns.sheHer:
        return 'She/Her';
      case Pronouns.theyThem:
        return 'They/Them';
      case Pronouns.zeZir:
        return 'Ze/Zir'; // Example of less common but valid pronouns
      case Pronouns.askMe:
        return 'Ask Me';
        // If you had an 'Other' case, you might handle it differently.
    }
  }

  // If your backend expects these exact string values, you can add a .value getter similar to VoteType.
  // For now, assuming the displayValue might be what's stored or you'll handle conversion.
  // String get backendValue => displayValue; // Example
}

/// Defines the chat availability status for a user.
/// Corresponds to ChatAvailabilityEnum in the backend.
enum ChatAvailability {
  openToChat,
  requestOnly,
  doNotDisturb,
}

extension ChatAvailabilityExtension on ChatAvailability {
  /// Returns the string value expected by the backend.
  String get backendValue {
    switch (this) {
      case ChatAvailability.openToChat:
        return 'open_to_chat';
      case ChatAvailability.requestOnly:
        return 'request_only';
      case ChatAvailability.doNotDisturb:
        return 'do_not_disturb';
    }
  }

  /// Returns a display-friendly string for the UI.
  String get displayValue {
    switch (this) {
      case ChatAvailability.openToChat:
        return 'Open to Chat';
      case ChatAvailability.requestOnly:
        return 'Request Only';
      case ChatAvailability.doNotDisturb:
        return 'Do Not Disturb';
    }
  }
}

/// Defines actions available in the user pop-up menu.
enum UserActionMenuItem {
  viewProfile,
  startChat,
  muteUser,
  blockUser,
  reportUser,
}