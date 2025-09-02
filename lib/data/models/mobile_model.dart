class Mobile {
  String mobileID; // Example property
  String mobileName; // Example property
  // Add other properties that your API returns for a mobile object

  Mobile({
    required this.mobileID,
    required this.mobileName,
    // Initialize other properties
  });

  factory Mobile.fromJson(Map<String, dynamic> json) {

    String requestMobileID;

    if (json['MobileID'] is int) {
      requestMobileID = json['MobileID'].toString();
    } else if (json['MobileID'] is String) {
      // Ensure it's a string representation of an int before assigning
      // You might want to add more robust validation if needed
      int.parse(
          json['MobileID']); // This will throw if not a valid int string
      requestMobileID = json['MobileID'];
    } else {
      // Handle cases where RequestID is null or not a String/int
      // You could throw an error, or assign a default, or make requestID nullable
      // For this example, let's throw an error if it's not what we expect
      throw FormatException(
          "RequestID is not a valid integer or string representation of an integer.");
    }

    return Mobile(
        mobileID: requestMobileID, mobileName: json['MobileName'] ?? ''
        // Map other properties
        );
  }

  // Optional: toJson method if you need to send Mobile objects back to an API
  Map<String, dynamic> toJson() {
    return {
      'MobileID': mobileID,
      'MobileName': mobileName,
    };
  }
}
