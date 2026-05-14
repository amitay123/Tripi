import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('he')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Tripi'**
  String get appName;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account & Profile'**
  String get settingsAccount;

  /// No description provided for @settingsTripPreferences.
  ///
  /// In en, this message translates to:
  /// **'Trip Preferences'**
  String get settingsTripPreferences;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get settingsSecurity;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppSettings;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & About'**
  String get settingsSupport;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get settingsPersonalDetails;

  /// No description provided for @settingsIntensityLevel.
  ///
  /// In en, this message translates to:
  /// **'Intensity Level'**
  String get settingsIntensityLevel;

  /// No description provided for @settingsTravelerDefaults.
  ///
  /// In en, this message translates to:
  /// **'Traveler Defaults'**
  String get settingsTravelerDefaults;

  /// No description provided for @settingsTripStyle.
  ///
  /// In en, this message translates to:
  /// **'Trip Style'**
  String get settingsTripStyle;

  /// No description provided for @settingsResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get settingsResetPassword;

  /// No description provided for @settingsSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get settingsSecurityAlerts;

  /// No description provided for @settingsActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get settingsActiveSessions;

  /// No description provided for @settingsTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get settingsTwoFactor;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Email Updates'**
  String get settingsEmailUpdates;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelpCenter;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// No description provided for @settingsDarkModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsDarkModeSystem;

  /// No description provided for @settingsDarkModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsDarkModeLight;

  /// No description provided for @settingsDarkModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDarkModeDark;

  /// No description provided for @settingsIntensityRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get settingsIntensityRelaxed;

  /// No description provided for @settingsIntensityRelaxedDesc.
  ///
  /// In en, this message translates to:
  /// **'Fewer stops, more free time'**
  String get settingsIntensityRelaxedDesc;

  /// No description provided for @settingsIntensityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get settingsIntensityBalanced;

  /// No description provided for @settingsIntensityBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Mix of activities and downtime'**
  String get settingsIntensityBalancedDesc;

  /// No description provided for @settingsIntensityIntensive.
  ///
  /// In en, this message translates to:
  /// **'Intensive'**
  String get settingsIntensityIntensive;

  /// No description provided for @settingsIntensityIntensiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Pack in as much as possible'**
  String get settingsIntensityIntensiveDesc;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית (Hebrew)'**
  String get settingsLanguageHebrew;

  /// No description provided for @settingsTravelerAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get settingsTravelerAdults;

  /// No description provided for @settingsTravelerChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get settingsTravelerChildren;

  /// No description provided for @settingsTravelerChildrenAge.
  ///
  /// In en, this message translates to:
  /// **'Ages 0–17'**
  String get settingsTravelerChildrenAge;

  /// No description provided for @settingsTripStyleAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get settingsTripStyleAdventure;

  /// No description provided for @settingsTripStyleCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get settingsTripStyleCultural;

  /// No description provided for @settingsTripStyleFood.
  ///
  /// In en, this message translates to:
  /// **'Food & Culinary'**
  String get settingsTripStyleFood;

  /// No description provided for @settingsTripStyleLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get settingsTripStyleLuxury;

  /// No description provided for @settingsTripStyleNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get settingsTripStyleNature;

  /// No description provided for @settingsTripStyleRelaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get settingsTripStyleRelaxation;

  /// No description provided for @settingsTripStyleNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get settingsTripStyleNightlife;

  /// No description provided for @settingsTripStyleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family-Friendly'**
  String get settingsTripStyleFamily;

  /// No description provided for @settingsTripStyleBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get settingsTripStyleBudget;

  /// No description provided for @settingsTripStyleCoastal.
  ///
  /// In en, this message translates to:
  /// **'Coastal & Beach'**
  String get settingsTripStyleCoastal;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get buttonApply;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonDone;

  /// No description provided for @buttonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of your account on this device.'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutConfirm;

  /// No description provided for @logoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay Signed In'**
  String get logoutCancel;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get changesSaved;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes will sync when connected.'**
  String get errorOffline;

  /// No description provided for @errorUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3–20 characters, lowercase, no spaces.'**
  String get errorUsernameInvalid;

  /// No description provided for @errorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get errorUsernameTaken;

  /// No description provided for @errorUsernameReserved.
  ///
  /// In en, this message translates to:
  /// **'This username is not available.'**
  String get errorUsernameReserved;

  /// No description provided for @currentDevice.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get currentDevice;

  /// No description provided for @activeSession.
  ///
  /// In en, this message translates to:
  /// **'Active Session'**
  String get activeSession;

  /// No description provided for @profileAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get profileAvatarChange;

  /// No description provided for @profileCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get profileCamera;

  /// No description provided for @profileGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profileGallery;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get profileRemovePhoto;

  /// No description provided for @securityRecentAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'For security, please re-enter your password to continue.'**
  String get securityRecentAuthRequired;

  /// No description provided for @securityPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get securityPasswordChanged;

  /// No description provided for @securityEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully'**
  String get securityEmailChanged;

  /// No description provided for @subscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get subscriptionFree;

  /// No description provided for @subscriptionPro.
  ///
  /// In en, this message translates to:
  /// **'Tripi Pro'**
  String get subscriptionPro;

  /// No description provided for @subscriptionPremium.
  ///
  /// In en, this message translates to:
  /// **'Tripi Premium'**
  String get subscriptionPremium;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Tripi'**
  String get settingsAbout;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get settingsRateApp;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsFeedback;
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
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
