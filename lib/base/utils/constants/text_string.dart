class BTexts {
  // On boarding Texts Logistics
  static const String onBoardingTitle1Logistics = "Welcome to MDMPI APP!";
  static const String onBoardingTitle2Logistics = "Add Your Deliveries";
  static const String onBoardingTitle3Logistics = "Track Your Deliveries";

  static const String onBoardingSubTitle1Logistics = "We’re thrilled to have you on board. With MDMPI APP - Logistics, managing and tracking your day to day deliveries is a breeze.";
  static const String onBoardingSubTitle2Logistics = "Enter the details of the deliverable, including the requester, document reference and client information.";
  static const String onBoardingSubTitle3Logistics = "Stay updated with real-time tracking and notifications for every step of the delivery process.";

  //  On boarding Texts Collection
  static const String onBoardingTitle1Collection = "Welcome to MDMPI APP!";
  static const String onBoardingTitle2Collection = "Add Your Collections";
  static const String onBoardingTitle3Collection = "Track Your Collections";

  static const String onBoardingSubTitle1Collection = "We’re thrilled to have you on board. With MDMPI APP Collection, managing and tracking your day to day collection is a breeze.";
  static const String onBoardingSubTitle2Collection = "Enter the details of the bank, the cheque number, including the amount, date, and remarks.";
  static const String onBoardingSubTitle3Collection= "Stay updated with real-time tracking and notifications for every step of the collection process.";

  //Collection Home Texts
  static const String collectionHomeTitle1 = "Welcome to MDMPI APP!";

  // Home Texts
  static const String homeTitle1 = "Dispatch an Item";
  static const String homeTitle2 = "Good morning";

  // Home
  static const String homeSubTitle1 = "Awaiting to Dispatch";
  static const String homeSubTitle2 = "Vehicles";
  static const String homeSubTitle3 = 'How would you like to start?';

  // Sign up Text
  static const String signupTitle = "Let's create your account";
  static const String firstname = "First name";
  static const String middleInitial = "Middle Initial";
  static const String lastname = "Last name";
  static const String initial = "Initial";
  static const String department = "Department";
  static const String mobile = "Mobile Number";
  static const String gender = "Gender";
  static const String designation = "Designation";
  static const String iAgreeTo = "I agree to";
  static const String privacyPolicy = "Privacy Policy";
  static const String and = "and";

  // Generate Shipment Texts
  static const String genShipmentTitle = "Generate \n Shipment Order";

  // Current Deliver Texts
  static const String currentDeliveryTitle = "Vehicle Activity";

  // Profile Texts
  static const String profileTitle = "Book Shipments";
  static const String profileSubTitle1 = "Accumulated minutes";
  static const String profileSubTitle2 = "Minutes accrued";

  // Login Headings Texts
  static const String loginTitle = "MDMPI APP";
  static const String loginSubTitle = "Logistics";
  static const String confirmEmail = "Verify your email address!";
  static const String confirmEmailSubTitle =
      "Congratulations! Your Account Awaits: Verify Your Email to Start Shopping and Experience a World of Unrivaled Deals and Personalized Offers.";
  static const String signInTitle = "Sign In";

  // Login Authentication Texts
  static const String username = "Username";
  static const String password = "Password";
  static const String email = "Email";
  static const String signIn = "Log In";
  static const String signUp = "Sign Up";
  static const String rememberMe = "Remember Me?";
  static const String forgetPassword = "Forget Password?";
  static const String createAccount = "Create Account";
  static const String orSignInWith = "or sign in with";
  static const String accountCreated = "Account Created Successfully!";
  static const String accountLoginToYour =
      "You can now log in to your account.";
  static const String tContinue = "Continue";
  static const String resendEmail = "Resend Email";
  static const String yourAccountCreatedTitle =
      "Your account successfully created!";
  static const String yourAccountCreatedSubTitle =
      "Welcome to Your Ultimate Shopping Destination: Your Account is Created, Unleash the Joy of Seamless Online Shopping!";
  static const String forgetPasswordTitle = "Forget password";
  static const String forgetPasswordSubTitle =
      "Don’t worry sometimes people can forget too, enter your email and we will send you a password reset link.";
  static const String changeYourPasswordTitle = "Password Reset Email Sent";
  static const String changeYourPasswordSubTitle =
      "Your Account Security is Our Priority! We've Sent You a Secure Link to Safely Change Your Password and Keep Your Account Protected.";

  /// AppBar Texts
  static const String homeAppbarTitle = "Logistics Dashboard";
  static const String homeAppbarSubTitle = "Good Day!";

  /// Dashboard Texts
  static const String dashboardTitle = "Activity Dashboard";
  static const String dashboardTotalRequests = "Total Requests:";
  static const String dashboardGettingSuppliesReady = "Getting Supplies Ready:";
  static const String dashboardItemsPrepared = "Items Prepared:";
  static const String dashboardForDelivery = "For Delivery:";
  static const String dashboardDelivered = "Delivered:";

  /// Request Texts
  static const String requestPackageIconText = "Request";

  /// Global Texts
  static const String skip = "Skip";
  static const String done = "Done";
  static const String submit = "Submit";
  static const String appName = "T-Store";

  /// Request Form Texts
  static const String requestFormTitle = "Let's Create Request";

  /// Generates a dynamic form title based on the category name
  /// Returns "Let's Create {categoryName} Request" if categoryName is provided
  /// Falls back to [requestFormTitle] if categoryName is null or empty
  static String getRequestFormTitle(String? categoryName) {
    if (categoryName == null || categoryName.trim().isEmpty) {
      return requestFormTitle;
    }
    return "$categoryName Form";
  }

  static const String client = "Client";
  static const String address = "Address";
  static const String phoneAddress = "Phone Number";
  static const String shippingMethod = "Shipping Method";
  static const String deliveryTerms = "Delivery Terms";
  static const String deliveryDate = "Delivery Date";

  /// Constants for status strings
  static const String statusGettingSuppliesReady = "Getting supplies ready";
  static const String statusForDelivery = "For Delivery";
  static const String statusItemPrepared = "Item Prepared";
  static const String statusDoneDelivery = "Delivered";
  static const String statusNewRequest = "New Request";
  static const String statusCancelled = "Cancelled";
  static const String statusInTransit = "In Transit";
  static const String statusTakenOut = "Taken Out";
  static const String statusAll = "All";
  static const String statusReceived = "Received";
  static const String statusItemPacked = "Item Packed";
  static const String statusEndorsedToGuard = "Endorsed to Guard";
  static const String statusForDispatch = "For Dispatch";
  static const String statusDispatch = "Dispatch";
  static const String statusDropOff = "Drop Off";
  static const String statusBackLoad = "Back Load";
  static const String statusProvincialPickUp = "Provincial Pick Up";
  static const String statusProvincialInTransit = "Provincial In Transit";
  static const String statusProvincialDelivered = "Provincial Delivered";

  /// Request Modal Specific Texts
  static const String requestModalDeliveryShotTitle = "Delivery Shot";
  static const String requestModalCloseButtonText = "Close";
  static const String requestModalImageNotFoundError =
      "Error: Delivery shot image not found.";
  static const String requestModalViewItemDeliveredText = "Proof Item Delivered";
  static const String requestModalViewItemReceivedText = "View Item Received";
  static const String requestModalPrepareItemButtonText = "Prepare Item";
  static const String requestModalPackedAndReadyButtonText =
      "Packed and Ready to Ship";
  static const String requestModalDropOffButtonText = "Drop Off";

  /// User Role
  static const String roleViewer = "Viewer";
  static const String roleRequest = "Request";
  static const String roleRelease = "Release";
  static const String roleCourier = "Courier";
  static const String roleAdmin = "Admin";
  static const String roleProvincial = "Provincial";

  // Labels
  static List<String> requestFormLabels = [
    'Standard Delivery',
    'Pull out',
    'Pick up',
    'Air / Sea',
    'Hotline Direct',
    'Stock receive',
  ];
}
