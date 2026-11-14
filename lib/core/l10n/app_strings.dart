import '../../state/notifiers/app_notifiers.dart';
import 'strings_common_and_home.dart';
import 'strings_studio.dart';

class AppStrings {
  const AppStrings._();

  static bool get isEs => appLanguageNotifier.value == 'es';

  static String get dockWallpapers => CommonAndHomeStrings.dockWallpapers;
  static String get dockStudio => CommonAndHomeStrings.dockStudio;
  static String get dockMusic => CommonAndHomeStrings.dockMusic;
  static String get dockSettings => CommonAndHomeStrings.dockSettings;

  static String get wallpapersTitle => CommonAndHomeStrings.wallpapersTitle;
  static String get newBtn => CommonAndHomeStrings.newBtn;
  static String savedLockScreens(int count) =>
      CommonAndHomeStrings.savedLockScreens(count);
  static String get sortRecent => CommonAndHomeStrings.sortRecent;
  static String get sortName => CommonAndHomeStrings.sortName;
  static String get noWallpapersTitle => CommonAndHomeStrings.noWallpapersTitle;
  static String get noWallpapersDesc => CommonAndHomeStrings.noWallpapersDesc;
  static String get openStudio => CommonAndHomeStrings.openStudio;
  static String get deleteWallpaperTitle =>
      CommonAndHomeStrings.deleteWallpaperTitle;
  static String deleteWallpaperConfirm(String name) =>
      CommonAndHomeStrings.deleteWallpaperConfirm(name);
  static String get cancel => CommonAndHomeStrings.cancel;
  static String get delete => CommonAndHomeStrings.delete;
  static String get rename => CommonAndHomeStrings.rename;
  static String get renameWallpaperTitle =>
      CommonAndHomeStrings.renameWallpaperTitle;
  static String get duplicate => CommonAndHomeStrings.duplicate;
  static String get setAsWallpaper =>
      CommonAndHomeStrings.setAsWallpaper;
  static String get customizeLockScreen =>
      CommonAndHomeStrings.customizeLockScreen;
  static String defaultProjectName(int day, int month) =>
      CommonAndHomeStrings.defaultProjectName(day, month);
  static String duplicateProjectName(String original) =>
      CommonAndHomeStrings.duplicateProjectName(original);
  static String get missingImageFile => CommonAndHomeStrings.missingImageFile;

  static String get retryBtn => CommonAndHomeStrings.retryBtn;
  static String get applyWallpaperError =>
      CommonAndHomeStrings.applyWallpaperError;
  static String get resetError => CommonAndHomeStrings.resetError;
  static String get syncSettingsError => CommonAndHomeStrings.syncSettingsError;
  static String get unsavedChangesBadge =>
      CommonAndHomeStrings.unsavedChangesBadge;
  static String get reopenPermissionTitle =>
      CommonAndHomeStrings.reopenPermissionTitle;
  static String get reopenPermissionDesc =>
      CommonAndHomeStrings.reopenPermissionDesc;
  static String get openSettingsBtn => CommonAndHomeStrings.openSettingsBtn;

  static String get settingsHeader => CommonAndHomeStrings.settingsHeader;
  static String get secLiveMusic => CommonAndHomeStrings.secLiveMusic;
  static String get liquidAlbumArtTitle =>
      CommonAndHomeStrings.liquidAlbumArtTitle;
  static String get liquidAlbumArtSub => CommonAndHomeStrings.liquidAlbumArtSub;
  static String get mediaSyncTitle => CommonAndHomeStrings.mediaSyncTitle;
  static String get musicSyncActive => CommonAndHomeStrings.musicSyncActive;
  static String get musicSyncRequired =>
      CommonAndHomeStrings.musicSyncRequired;
  static String get musicPermGrantedBtn =>
      CommonAndHomeStrings.musicPermGrantedBtn;
  static String get musicPermGrantBtn =>
      CommonAndHomeStrings.musicPermGrantBtn;
  static String get targetMusicPlayer => CommonAndHomeStrings.targetMusicPlayer;
  static String get playerAll => CommonAndHomeStrings.playerAll;
  static String get secAppTheme => CommonAndHomeStrings.secAppTheme;
  static String get themeDark => CommonAndHomeStrings.themeDark;
  static String get themeLight => CommonAndHomeStrings.themeLight;
  static String get secLanguageHeader => CommonAndHomeStrings.secLanguageHeader;
  static String get secClockDisplayHeader =>
      CommonAndHomeStrings.secClockDisplayHeader;
  static String get homescreenClock => CommonAndHomeStrings.homescreenClock;
  static String get homescreenClockSub =>
      CommonAndHomeStrings.homescreenClockSub;
  static String get use24HourFormat => CommonAndHomeStrings.use24HourFormat;
  static String get use24HourFormatSub =>
      CommonAndHomeStrings.use24HourFormatSub;
  static String get secAboutHeader => CommonAndHomeStrings.secAboutHeader;
  static String get replayOnboarding => CommonAndHomeStrings.replayOnboarding;
  static String get versionLabel => CommonAndHomeStrings.versionLabel;

  static String get nextBtn => CommonAndHomeStrings.nextBtn;
  static String get enterStudioBtn => CommonAndHomeStrings.enterStudioBtn;
  static String get onbSlide1Title => CommonAndHomeStrings.onbSlide1Title;
  static String get onbSlide1Sub => CommonAndHomeStrings.onbSlide1Sub;
  static String get onbSlide2Title => CommonAndHomeStrings.onbSlide2Title;
  static String get onbSlide2Sub => CommonAndHomeStrings.onbSlide2Sub;
  static String get onbSlide3Title => CommonAndHomeStrings.onbSlide3Title;
  static String get onbSlide3Sub => CommonAndHomeStrings.onbSlide3Sub;
  static String get onbPermTitle => CommonAndHomeStrings.onbPermTitle;
  static String get onbPermSub => CommonAndHomeStrings.onbPermSub;
  static String get onbStorageTitle => CommonAndHomeStrings.onbStorageTitle;
  static String get onbStorageDesc => CommonAndHomeStrings.onbStorageDesc;
  static String get onbStorageGranted => CommonAndHomeStrings.onbStorageGranted;
  static String get onbStorageAllow => CommonAndHomeStrings.onbStorageAllow;
  static String get onbMusicTitle => CommonAndHomeStrings.onbMusicTitle;
  static String get onbMusicDesc => CommonAndHomeStrings.onbMusicDesc;
  static String get onbMusicGranted => CommonAndHomeStrings.onbMusicGranted;
  static String get onbMusicAllow => CommonAndHomeStrings.onbMusicAllow;
  static String get onbRestrictedTitle =>
      CommonAndHomeStrings.onbRestrictedTitle;
  static String get onbRestrictedDesc => CommonAndHomeStrings.onbRestrictedDesc;
  static String get onbOpenAppInfoBtn => CommonAndHomeStrings.onbOpenAppInfoBtn;

  static String get studioTitle => StudioStrings.studioTitle;
  static String get apply => StudioStrings.apply;
  static String get reset => StudioStrings.reset;
  static String get resetStudioTitle => StudioStrings.resetStudioTitle;
  static String get resetStudioDesc => StudioStrings.resetStudioDesc;
  static String get bgRequiredTitle => StudioStrings.bgRequiredTitle;
  static String get bgRequiredDesc => StudioStrings.bgRequiredDesc;
  static String get loadingBg => StudioStrings.loadingBg;
  static String get loadingFg => StudioStrings.loadingFg;
  static String get applyingWallpaper => StudioStrings.applyingWallpaper;
  static String get noLayersLoaded => StudioStrings.noLayersLoaded;
  static String get selectLayersBelow => StudioStrings.selectLayersBelow;

  static String get segBackground => StudioStrings.segBackground;
  static String get segClock => StudioStrings.segClock;
  static String get segDate => StudioStrings.segDate;
  static String get segMaterial => StudioStrings.segMaterial;

  static String get secWallpaperLayers => StudioStrings.secWallpaperLayers;
  static String get btnStep1Bg => StudioStrings.btnStep1Bg;
  static String get btnChangeBg => StudioStrings.btnChangeBg;
  static String get btnStep2Png => StudioStrings.btnStep2Png;
  static String get btnChangePng => StudioStrings.btnChangePng;
  static String get removeSubjectOverlay => StudioStrings.removeSubjectOverlay;

  static String get secDepth => StudioStrings.secDepth;
  static String get depthLayering => StudioStrings.depthLayering;
  static String get layerStandard => StudioStrings.layerStandard;
  static String get layerHoursFront => StudioStrings.layerHoursFront;
  static String get layerMinutesFront => StudioStrings.layerMinutesFront;

  static String get secBackgroundDim => StudioStrings.secBackgroundDim;
  static String get dimBackgroundLabel => StudioStrings.dimBackgroundLabel;

  static String get secClockPosition => StudioStrings.secClockPosition;
  static String get openPositionPicker => StudioStrings.openPositionPicker;
  static String get openPositionPickerSub =>
      StudioStrings.openPositionPickerSub;
  static String get positionPickerTitle => StudioStrings.positionPickerTitle;
  static String get sizeLabel => StudioStrings.sizeLabel;
  static String get presetsLabel => StudioStrings.presetsLabel;
  static String get fineAdjustLabel => StudioStrings.fineAdjustLabel;

  static String get secClockStructure => StudioStrings.secClockStructure;
  static String get clockDisplay => StudioStrings.clockDisplay;
  static String get horizontal => StudioStrings.horizontal;
  static String get vertical => StudioStrings.vertical;
  static String get clockStyle => StudioStrings.clockStyle;

  static String get secTypeface => StudioStrings.secTypeface;
  static String get addCustomFont => StudioStrings.addCustomFont;
  static String get customFontsHeader => StudioStrings.customFontsHeader;

  static String get secClockColor => StudioStrings.secClockColor;
  static String get separateMinutes => StudioStrings.separateMinutes;
  static String get clockUnifiedColor => StudioStrings.clockUnifiedColor;
  static String get hourColor => StudioStrings.hourColor;
  static String get minuteColor => StudioStrings.minuteColor;

  static String get secFontProportions => StudioStrings.secFontProportions;
  static String get letterSpacing => StudioStrings.letterSpacing;
  static String get verticalStretch => StudioStrings.verticalStretch;
  static String get hoursMinutesGap => StudioStrings.hoursMinutesGap;

  static String get secDateVisibility => StudioStrings.secDateVisibility;
  static String get showDate => StudioStrings.showDate;
  static String get uppercaseText => StudioStrings.uppercaseText;
  static String get boldWeight => StudioStrings.boldWeight;

  static String get secDatePosScale => StudioStrings.secDatePosScale;
  static String get datePositionPickerTitle =>
      StudioStrings.datePositionPickerTitle;
  static String get openDatePositionPicker =>
      StudioStrings.openDatePositionPicker;
  static String get openDatePositionPickerSub =>
      StudioStrings.openDatePositionPickerSub;

  static String get secDateFormat => StudioStrings.secDateFormat;
  static String get secDateColorAndFont =>
      StudioStrings.secDateColorAndFont;
  static String get secDateColor => StudioStrings.secDateColor;
  static String get secDateTypeface => StudioStrings.secDateTypeface;
  static String get secDateMaterial => StudioStrings.secDateMaterial;

  static String get secSurfaceMaterial => StudioStrings.secSurfaceMaterial;
  static String get matSolid => StudioStrings.matSolid;
  static String get matLiquid => StudioStrings.matLiquid;
  static String get matAero => StudioStrings.matAero;
  static String get matAcrylic => StudioStrings.matAcrylic;
  static String get backdropBlur => StudioStrings.backdropBlur;
  static String get glassBrightness => StudioStrings.glassBrightness;
  static String get clockOpacity => StudioStrings.clockOpacity;
  static String get dateOpacity => StudioStrings.dateOpacity;
  static String get depthDropShadow => StudioStrings.depthDropShadow;

  static String get secGlassRim => StudioStrings.secGlassRim;
  static String get enableGlassRim => StudioStrings.enableGlassRim;
  static String get rimThickness => StudioStrings.rimThickness;
  static String get rimOpacity => StudioStrings.rimOpacity;
  static String get rimGlowBlur => StudioStrings.rimGlowBlur;

  static String get secAnimStyle => StudioStrings.secAnimStyle;
  static String get animNone => StudioStrings.animNone;
  static String get animFade => StudioStrings.animFade;
  static String get animSlideUp => StudioStrings.animSlideUp;
  static String get animSlideDown => StudioStrings.animSlideDown;
  static String get animScaleUp => StudioStrings.animScaleUp;
  static String get animScaleDown => StudioStrings.animScaleDown;
  static String get animDuration => StudioStrings.animDuration;
  static String get animOnScreenOn => StudioStrings.animOnScreenOn;
  static String get animOnUnlock => StudioStrings.animOnUnlock;
  static String get btnTestAnimIn => StudioStrings.btnTestAnimIn;
  static String get btnTestAnimOut => StudioStrings.btnTestAnimOut;

  static String get colorSpectrum => StudioStrings.colorSpectrum;
  static String get materialYouAccents =>
      StudioStrings.materialYouAccents;
  static String get applyColor => StudioStrings.applyColor;

  static String get musicTitle => StudioStrings.musicTitle;
  static String get segMusicLayout => StudioStrings.segMusicLayout;
  static String get segMusicFonts => StudioStrings.segMusicFonts;
  static String get segMusicMaterial => StudioStrings.segMusicMaterial;
  static String get secMusicTarget => StudioStrings.secMusicTarget;
  static String get targetCover => StudioStrings.targetCover;
  static String get targetCard => StudioStrings.targetCard;
  static String get targetClockDate => StudioStrings.targetClockDate;
  static String get horizontalPosLabel =>
      StudioStrings.horizontalPosLabel;
  static String get verticalPosLabel =>
      StudioStrings.verticalPosLabel;
  static String get scaleLabel => StudioStrings.scaleLabel;
  static String get secMusicClockFont =>
      StudioStrings.secMusicClockFont;
  static String get secMusicDateFont =>
      StudioStrings.secMusicDateFont;
  static String get secMusicCardFont =>
      StudioStrings.secMusicCardFont;
  static String get secMusicClockMaterial =>
      StudioStrings.secMusicClockMaterial;
  static String get secMusicCardMaterial =>
      StudioStrings.secMusicCardMaterial;
  static String get secMusicClockRim =>
      StudioStrings.secMusicClockRim;
  static String get secMusicCardRim =>
      StudioStrings.secMusicCardRim;
}