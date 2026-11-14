import '../../state/notifiers/app_notifiers.dart';

class CommonAndHomeStrings {
  const CommonAndHomeStrings._();

  static bool get _es => appLanguageNotifier.value == 'es';

  static String get dockWallpapers => _es ? 'Fondos' : 'Wallpapers';
  static String get dockStudio => _es ? 'Estudio' : 'Studio';
  static String get dockMusic => _es ? 'Música' : 'Music';
  static String get dockSettings => _es ? 'Ajustes' : 'Settings';

  static String get wallpapersTitle =>
      _es ? 'Fondos de pantalla' : 'Wallpapers';
  static String get newBtn => _es ? 'Añadir' : 'Add';
  static String savedLockScreens(int count) =>
      _es ? 'Pantallas de bloqueo guardadas ($count)' : 'Saved lock screens ($count)';
  static String get sortRecent => _es ? 'Recientes' : 'Recent';
  static String get sortName => _es ? 'Nombre' : 'Name';
  static String get noWallpapersTitle =>
      _es ? 'Sin fondos de pantalla' : 'No wallpapers';
  static String get noWallpapersDesc => _es
      ? 'Crea un diseño con efecto de profundidad en Estudio.'
      : 'Create a design with depth effect in Studio.';
  static String get openStudio => _es ? 'Abrir Estudio' : 'Open Studio';
  static String get deleteWallpaperTitle =>
      _es ? 'Eliminar fondo de pantalla' : 'Delete wallpaper';
  static String deleteWallpaperConfirm(String name) =>
      _es ? 'Se eliminará "$name".' : '"$name" will be deleted.';
  static String get cancel => _es ? 'Cancelar' : 'Cancel';
  static String get delete => _es ? 'Eliminar' : 'Delete';
  static String get rename => _es ? 'Renombrar' : 'Rename';
  static String get renameWallpaperTitle =>
      _es ? 'Renombrar fondo' : 'Rename wallpaper';
  static String get duplicate => _es ? 'Duplicar' : 'Duplicate';
  static String get setAsWallpaper =>
      _es ? 'Establecer como fondo de pantalla' : 'Set as wallpaper';
  static String get customizeLockScreen =>
      _es ? 'Editar en Estudio' : 'Edit in Studio';
  static String defaultProjectName(int day, int month) =>
      _es ? 'Pantalla de bloqueo $day/$month' : 'Lock Screen $day/$month';
  static String duplicateProjectName(String original) =>
      _es ? '$original (Copia)' : '$original (Copy)';
  static String get missingImageFile =>
      _es ? 'Archivo no encontrado' : 'Image file missing';

  static String get retryBtn => _es ? 'Reintentar' : 'Retry';
  static String get applyWallpaperError => _es
      ? 'No se pudo aplicar el fondo de pantalla.'
      : 'Could not apply wallpaper.';
  static String get resetError => _es
      ? 'No se pudo restablecer el diseño.'
      : 'Could not reset design.';
  static String get syncSettingsError => _es
      ? 'No se pudieron sincronizar los ajustes.'
      : 'Could not sync settings.';
  static String get unsavedChangesBadge => _es ? 'Sin aplicar' : 'Unapplied';
  static String get reopenPermissionTitle =>
      _es ? 'Permiso ya concedido' : 'Permission already granted';
  static String get reopenPermissionDesc => _es
      ? 'Este acceso ya está activado. ¿Deseas abrir los ajustes del sistema de todas formas?'
      : 'This access is already enabled. Do you want to open system settings anyway?';
  static String get openSettingsBtn =>
      _es ? 'Abrir ajustes' : 'Open settings';

  static String get settingsHeader => _es ? 'Ajustes' : 'Settings';
  static String get secLiveMusic =>
      _es ? 'Música en reproducción' : 'Now playing';
  static String get liquidAlbumArtTitle =>
      _es ? 'Carátula a pantalla completa' : 'Full-screen album art';
  static String get liquidAlbumArtSub => _es
      ? 'Oculta el sujeto y adapta el color del reloj a la música en reproducción.'
      : 'Hides the subject and tints the clock to match current music.';
  static String get mediaSyncTitle =>
      _es ? 'Sincronización multimedia' : 'Media sync';
  static String get musicSyncActive => _es ? 'Activado' : 'Active';
  static String get musicSyncRequired =>
      _es ? 'Permiso requerido' : 'Permission required';
  static String get musicPermGrantedBtn =>
      _es ? 'Administrar permisos' : 'Manage permissions';
  static String get musicPermGrantBtn =>
      _es ? 'Permitir acceso a notificaciones' : 'Allow notification access';
  static String get targetMusicPlayer =>
      _es ? 'Reproductor de música' : 'Music player';
  static String get playerAll =>
      _es ? 'Todas las aplicaciones' : 'All apps';
  static String get secAppTheme => _es ? 'Apariencia' : 'Appearance';
  static String get themeDark => _es ? 'Modo oscuro' : 'Dark mode';
  static String get themeLight => _es ? 'Modo claro' : 'Light mode';
  static String get secLanguageHeader => _es ? 'Idioma' : 'Language';
  static String get secClockDisplayHeader =>
      _es ? 'Pantalla de inicio' : 'Home screen';
  static String get homescreenClock =>
      _es ? 'Mostrar reloj en Inicio' : 'Show clock on Home screen';
  static String get homescreenClockSub => _es
      ? 'Si se desactiva, el reloj solo se mostrará en la pantalla de bloqueo.'
      : 'When off, the clock only appears on the Lock screen.';
  static String get use24HourFormat =>
      _es ? 'Formato de 24 horas' : '24-hour time';
  static String get use24HourFormatSub =>
      _es ? '13:00 en lugar de 1:00 p. m.' : '13:00 instead of 1:00 PM';
  static String get secAboutHeader => _es ? 'Información' : 'About';
  static String get replayOnboarding =>
      _es ? 'Ver guía de inicio' : 'View welcome guide';
  static String get versionLabel => _es ? 'Versión' : 'Version';

  static String get nextBtn => _es ? 'Siguiente' : 'Next';
  static String get enterStudioBtn => _es ? 'Continuar' : 'Continue';

  static String get onbSlide1Title =>
      _es ? 'Efecto de Profundidad' : 'Depth Effect';
  static String get onbSlide1Sub =>
      _es ? 'Tus fotos en primer plano' : 'Your photos in the foreground';

  static String get onbSlide2Title => 'Liquid Glass';
  static String get onbSlide2Sub => _es
      ? 'Reflejos reales y transparencia dinámica'
      : 'Real reflections and dynamic transparency';

  static String get onbSlide3Title =>
      _es ? 'En Reproducción' : 'Now Playing';
  static String get onbSlide3Sub =>
      _es ? 'Sincronizado con tu música' : 'Synced with your music';

  static String get onbPermTitle =>
      _es ? 'Configuración de permisos' : 'Permission setup';
  static String get onbPermSub => _es
      ? 'Conceda los accesos requeridos para cargar imágenes y sincronizar la reproducción.'
      : 'Grant the required accesses to load images and sync playback.';

  static String get onbStorageTitle =>
      _es ? 'Fotos y vídeos' : 'Photos & videos';
  static String get onbStorageDesc => _es
      ? 'Requerido para seleccionar imágenes de fondo y sujetos.'
      : 'Required to select background images and subjects.';
  static String get onbStorageGranted => _es ? 'Permitido' : 'Allowed';
  static String get onbStorageAllow => _es ? 'Permitir' : 'Allow';

  static String get onbMusicTitle =>
      _es ? 'Acceso a notificaciones' : 'Notification access';
  static String get onbMusicDesc => _es
      ? 'Requerido para mostrar la carátula del álbum en la pantalla de bloqueo.'
      : 'Required to display album art on the lock screen.';
  static String get onbMusicGranted => _es ? 'Permitido' : 'Allowed';
  static String get onbMusicAllow => _es ? 'Permitir' : 'Allow';

  static String get onbRestrictedTitle =>
      _es ? 'Ajustes restringidos' : 'Restricted settings';
  static String get onbRestrictedDesc => _es
      ? 'Abra Información de la aplicación, toque Más (⋮) y seleccione «Permitir ajustes restringidos».'
      : 'Open App info, tap More (⋮), and select "Allow restricted settings".';
  static String get onbOpenAppInfoBtn =>
      _es ? 'Información de la aplicación' : 'App info';
}