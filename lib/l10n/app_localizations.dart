import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NAGA'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Detect Visual\nPollution'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered detection for cleaner cities.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'NAGA'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Description.
  ///
  /// In en, this message translates to:
  /// **'AI-powered visual pollution detection for cleaner cities.'**
  String get onboarding1Description;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Description.
  ///
  /// In en, this message translates to:
  /// **'Three simple steps to detect and report visual pollution instantly'**
  String get onboarding2Description;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Together for Cleaner Cities'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Description.
  ///
  /// In en, this message translates to:
  /// **'Your reports can make a real difference. Let\'s build cleaner and more beautiful cities.'**
  String get onboarding3Description;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get start;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Capture or Upload'**
  String get step1Title;

  /// No description provided for @step1Desc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload one from your gallery.'**
  String get step1Desc;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'AI Detection'**
  String get step2Title;

  /// No description provided for @step2Desc.
  ///
  /// In en, this message translates to:
  /// **'Our AI analyzes the image and identifies visual pollution.'**
  String get step2Desc;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get step3Title;

  /// No description provided for @step3Desc.
  ///
  /// In en, this message translates to:
  /// **'Send the report with details to help improve your city.'**
  String get step3Desc;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'Sign in '**
  String get loginSubtitleHighlight;

  /// No description provided for @loginSubtitleRest.
  ///
  /// In en, this message translates to:
  /// **' to continue monitoring and reporting visual pollution.'**
  String get loginSubtitleRest;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createAccountText.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get createAccountText;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'Create your account '**
  String get createAccountSubtitleHighlight;

  /// No description provided for @createAccountSubtitleRest.
  ///
  /// In en, this message translates to:
  /// **' to start reporting visual pollution using AI.'**
  String get createAccountSubtitleRest;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @nagaTitle.
  ///
  /// In en, this message translates to:
  /// **'NAGA'**
  String get nagaTitle;

  /// No description provided for @nagaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered visual pollution detection for cleaner cities.'**
  String get nagaSubtitle;

  /// No description provided for @togetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Together for Cleaner Cities'**
  String get togetherTitle;

  /// No description provided for @togetherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every report makes a real difference.\nLet’s build a better tomorrow.'**
  String get togetherSubtitle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Together, let\'s keep our cities clean and beautiful.'**
  String get homeSubtitle;

  /// No description provided for @reportPollutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Visual Pollution'**
  String get reportPollutionTitle;

  /// No description provided for @reportPollutionSub.
  ///
  /// In en, this message translates to:
  /// **'Capture or upload media to report visual pollution.'**
  String get reportPollutionSub;

  /// No description provided for @reportsSummary.
  ///
  /// In en, this message translates to:
  /// **'Your Reports Summary'**
  String get reportsSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get recentReports;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet.'**
  String get noReports;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get navMyReports;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @visualPollution.
  ///
  /// In en, this message translates to:
  /// **'Visual Pollution'**
  String get visualPollution;

  /// No description provided for @createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @originalImage.
  ///
  /// In en, this message translates to:
  /// **'Original Image'**
  String get originalImage;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @processedImage.
  ///
  /// In en, this message translates to:
  /// **'Processed Image'**
  String get processedImage;

  /// No description provided for @detectPollution.
  ///
  /// In en, this message translates to:
  /// **'Detect Pollution'**
  String get detectPollution;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @openTicket.
  ///
  /// In en, this message translates to:
  /// **'Open Ticket'**
  String get openTicket;

  /// No description provided for @aiAnalysisResults.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Results'**
  String get aiAnalysisResults;

  /// No description provided for @noPollutionDetected.
  ///
  /// In en, this message translates to:
  /// **'No visual pollution detected.'**
  String get noPollutionDetected;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Image...'**
  String get analyzingImage;

  /// No description provided for @detectingElements.
  ///
  /// In en, this message translates to:
  /// **'Detecting visual pollution elements'**
  String get detectingElements;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your network.'**
  String get connectionError;

  /// No description provided for @originalVideo.
  ///
  /// In en, this message translates to:
  /// **'Original Video'**
  String get originalVideo;

  /// No description provided for @processedVideo.
  ///
  /// In en, this message translates to:
  /// **'Processed Video'**
  String get processedVideo;

  /// No description provided for @analyzingVideo.
  ///
  /// In en, this message translates to:
  /// **'Analyzing video...'**
  String get analyzingVideo;

  /// No description provided for @detectingVideoElements.
  ///
  /// In en, this message translates to:
  /// **'Detecting visual pollution elements in the video'**
  String get detectingVideoElements;

  /// No description provided for @reanalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reanalyze;

  /// No description provided for @videoAnalysisCompleted.
  ///
  /// In en, this message translates to:
  /// **'Video analysis completed'**
  String get videoAnalysisCompleted;

  /// No description provided for @noPollutionDetectedInVideo.
  ///
  /// In en, this message translates to:
  /// **'No visual pollution was detected in the video.'**
  String get noPollutionDetectedInVideo;

  /// No description provided for @videoDescription.
  ///
  /// In en, this message translates to:
  /// **'AI Generated Video Description'**
  String get videoDescription;

  /// No description provided for @editVideoDescription.
  ///
  /// In en, this message translates to:
  /// **'You can edit this description while opening the ticket.'**
  String get editVideoDescription;

  /// No description provided for @createNewTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Ticket'**
  String get createNewTicketTitle;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter the details of the visual pollution issue you\'ve detected'**
  String get enterDetails;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionLabel;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @selectPollutionElements.
  ///
  /// In en, this message translates to:
  /// **'Select Pollution Elements'**
  String get selectPollutionElements;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search Location'**
  String get searchLocation;

  /// No description provided for @selectedAddress.
  ///
  /// In en, this message translates to:
  /// **'Selected Address:'**
  String get selectedAddress;

  /// No description provided for @submitTicketBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get submitTicketBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get manageAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @leaveBlankKeepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current password'**
  String get leaveBlankKeepCurrent;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match!'**
  String get passwordsDoNotMatch;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile.'**
  String get profileUpdateFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorOccurred;

  /// No description provided for @profileUpdatedAutoLogout.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully. You will be logged out automatically in 5 seconds.'**
  String get profileUpdatedAutoLogout;

  /// No description provided for @logoutNow.
  ///
  /// In en, this message translates to:
  /// **'Logout Now'**
  String get logoutNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
