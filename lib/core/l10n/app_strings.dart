import '../../state/notifiers/app_notifiers.dart';


class AppStrings {
  const AppStrings._();

  static bool get isEs => appLanguageNotifier.value == 'es';


  static String get dockWallpapers => isEs ? 'Fondos' : 'Wallpapers';
  static String get dockStudio     => isEs ? 'Estudio' : 'Studio';
  static String get dockSettings   => isEs ? 'Ajustes' : 'Settings';


  static String get wallpapersTitle =>
      isEs ? 'Fondos de pantalla' : 'Wallpapers';
  static String get newBtn => isEs ? 'Añadir' : 'Add';
  static String savedLockScreens(int count) =>
      isEs ? 'Pantallas de bloqueo guardadas ($count)' : 'Saved lock screens ($count)';
  static String get sortRecent => isEs ? 'Recientes' : 'Recent';
  static String get sortName   => isEs ? 'Nombre' : 'Name';
  static String get noWallpapersTitle =>
      isEs ? 'Sin fondos de pantalla' : 'No wallpapers';
  static String get noWallpapersDesc => isEs
      ? 'Crea un diseño con efecto de profundidad en Estudio.'
      : 'Create a design with depth effect in Studio.';
  static String get openStudio => isEs ? 'Abrir Estudio' : 'Open Studio';
  static String get deleteWallpaperTitle =>
      isEs ? 'Eliminar fondo de pantalla' : 'Delete wallpaper';
  static String deleteWallpaperConfirm(String name) =>
      isEs ? 'Se eliminará "$name".' : '"$name" will be deleted.';
  static String get cancel            => isEs ? 'Cancelar' : 'Cancel';
  static String get delete            => isEs ? 'Eliminar' : 'Delete';
  static String get rename            => isEs ? 'Renombrar' : 'Rename';
  static String get renameWallpaperTitle => isEs ? 'Renombrar fondo' : 'Rename wallpaper';
  static String get duplicate         => isEs ? 'Duplicar' : 'Duplicate';
  static String get setAsWallpaper    => isEs ? 'Establecer como fondo de pantalla' : 'Set as wallpaper';
  static String get customizeLockScreen =>
      isEs ? 'Editar en Estudio' : 'Edit in Studio';


  static String get studioTitle => isEs ? 'Estudio' : 'Studio';
  static String get apply       => isEs ? 'Aplicar' : 'Apply';
  static String get reset       => isEs ? 'Restablecer' : 'Reset';
  static String get resetStudioTitle =>
      isEs ? 'Restablecer diseño' : 'Reset design';
  static String get resetStudioDesc => isEs
      ? 'Se eliminarán las fotos actuales y se restaurarán los valores predeterminados.'
      : 'Current photos will be removed and default values restored.';
  static String get bgRequiredTitle =>
      isEs ? 'Fondo no seleccionado' : 'Background required';
  static String get bgRequiredDesc => isEs
      ? 'Seleccione una foto de fondo antes de añadir un sujeto.'
      : 'Select a background photo before adding a subject.';
  static String get loadingBg   => isEs ? 'Cargando fondo…' : 'Loading background…';
  static String get loadingFg   => isEs ? 'Cargando sujeto…' : 'Loading subject…';
  static String get applyingWallpaper =>
      isEs ? 'Aplicando fondo de pantalla…' : 'Applying wallpaper…';
  static String get noLayersLoaded =>
      isEs ? 'Sin foto seleccionada' : 'No photo selected';
  static String get selectLayersBelow => isEs
      ? 'Seleccione un fondo y un sujeto para comenzar.'
      : 'Select a background and subject to start.';


  static String get segBackground => isEs ? 'Fondo'   : 'Background';
  static String get segClock      => isEs ? 'Reloj'   : 'Clock';
  static String get segDate       => isEs ? 'Fecha'   : 'Date';
  static String get segMaterial   => isEs ? 'Efectos' : 'Effects';
  static String get segAnimations => isEs ? 'Efectos' : 'Effects';


  static String get secWallpaperLayers => isEs ? 'Capas' : 'Layers';
  static String get btnStep1Bg       => isEs ? 'Fondo'        : 'Background';
  static String get btnChangeBg      => isEs ? 'Cambiar fondo' : 'Change photo';
  static String get btnStep2Png      => isEs ? 'Sujeto'       : 'Subject';
  static String get btnChangePng     => isEs ? 'Cambiar sujeto' : 'Change subject';
  static String get removeSubjectOverlay =>
      isEs ? 'Eliminar sujeto' : 'Remove subject';

  static String get secDepth            => isEs ? 'Profundidad' : 'Depth';
  static String get depthLayering       => isEs ? 'Profundidad' : 'Depth';
  static String get layerStandard       => isEs ? 'Estándar'    : 'Standard';
  static String get layerHoursFront     => isEs ? 'Horas del.'       : 'Hours front';
  static String get layerMinutesFront   => isEs ? 'Minutos del.'     : 'Min. front';

  static String get secBackgroundDim  => isEs ? 'Iluminación'      : 'Lighting';
  static String get dimBackgroundLabel => isEs ? 'Atenuar fondo'   : 'Dim background';

  static String get secClockPosition  => isEs ? 'Posición' : 'Position';
  static String get openPositionPicker =>
      isEs ? 'Ajustar posición' : 'Adjust position';
  static String get openPositionPickerSub => isEs
      ? 'Cuadrícula, preajustes y tamaño'
      : 'Grid, presets and size';
  static String get positionPickerTitle =>
      isEs ? 'Posición del reloj' : 'Clock position';
  static String get sizeLabel      => isEs ? 'Tamaño'     : 'Size';
  static String get presetsLabel   => isEs ? 'Preajustes' : 'Presets';
  static String get fineAdjustLabel => isEs ? 'Ajuste fino' : 'Fine tuning';

  static String get secClockStructure => isEs ? 'Disposición' : 'Layout';
  static String get clockDisplay      => isEs ? 'Alineación'  : 'Alignment';
  static String get horizontal        => isEs ? 'Horizontal'  : 'Horizontal';
  static String get vertical          => isEs ? 'Vertical'    : 'Vertical';
  static String get clockStyle        => isEs ? 'Formato'     : 'Format';

  static String get secTypeface => isEs ? 'Tipografía' : 'Typeface';

  static String get secClockColor      => isEs ? 'Color'            : 'Color';
  static String get separateMinutes    => isEs ? 'Separar minutos'  : 'Separate minutes';
  static String get clockUnifiedColor  => isEs ? 'Reloj'            : 'Clock';
  static String get hourColor          => isEs ? 'Hora'             : 'Hours';
  static String get minuteColor        => isEs ? 'Minutos'          : 'Minutes';
  static String get hourTint           => isEs ? 'Hora'             : 'Hours';
  static String get minuteTint         => isEs ? 'Minutos'          : 'Minutes';

  static String get secFontProportions => isEs ? 'Proporciones'       : 'Proportions';
  static String get letterSpacing      => isEs ? 'Espaciado'          : 'Spacing';
  static String get verticalStretch    => isEs ? 'Altura vertical'    : 'Vertical height';
  static String get hoursMinutesGap    => isEs ? 'Espacio entre líneas' : 'Line gap';


  static String get secDateVisibility => isEs ? 'Visibilidad' : 'Visibility';
  static String get showDate          => isEs ? 'Mostrar fecha' : 'Show date';
  static String get uppercaseText     => isEs ? 'Mayúsculas'    : 'Uppercase';
  static String get boldWeight        => isEs ? 'Negrita'       : 'Bold';

  static String get secDatePosScale => isEs ? 'Posición' : 'Position';
  static String get datePositionPickerTitle =>
      isEs ? 'Posición de la fecha' : 'Date position';
  static String get openDatePositionPicker =>
      isEs ? 'Ajustar fecha' : 'Adjust date';
  static String get openDatePositionPickerSub => isEs
      ? 'Ubicación y tamaño en pantalla'
      : 'Placement and size on screen';

  static String get secDateFormat       => isEs ? 'Formato'        : 'Format';
  static String get secDateColorAndFont => isEs ? 'Color y fuente' : 'Color & font';
  static String get secDateColor        => isEs ? 'Color'          : 'Color';
  static String get secDateTypeface     => isEs ? 'Tipografía'     : 'Typeface';


  static String get secSurfaceMaterial => isEs ? 'Material' : 'Material';
  static String get matSolid           => isEs ? 'Sólido'   : 'Solid';
  static String get matLiquid          => isEs ? 'Cristal'  : 'Glass';
  static String get matAero            => isEs ? 'Mica'     : 'Mica';
  static String get matAcrylic         => isEs ? 'Acrílico' : 'Acrylic';
  static String get backdropBlur       => isEs ? 'Desenfoque' : 'Blur';
  static String get glassBrightness    => isEs ? 'Brillo'     : 'Brightness';
  static String get specularBrightness => isEs ? 'Brillo'     : 'Brightness';
  static String get clockOpacity       => isEs ? 'Opacidad'   : 'Opacity';
  static String get depthDropShadow    => isEs ? 'Sombra'     : 'Shadow';

  static String get secGlassRim     => isEs ? 'Borde de cristal' : 'Glass edge';
  static String get enableGlassRim  => isEs ? 'Contorno'         : 'Outline';
  static String get rimThickness    => isEs ? 'Grosor'           : 'Thickness';
  static String get rimOpacity      => isEs ? 'Opacidad'         : 'Opacity';
  static String get rimGlowBlur     => isEs ? 'Resplandor'       : 'Glow';

  static String get secAnimStyle  => isEs ? 'Transición' : 'Transition';
  static String get secAnimTiming => isEs ? 'Transición' : 'Transition';
  static String get animNone      => isEs ? 'Ninguna'     : 'None';
  static String get animFade      => isEs ? 'Desvanecer'  : 'Fade';
  static String get animSlideUp   => isEs ? 'Deslizar arriba' : 'Slide up';
  static String get animSlideDown => isEs ? 'Deslizar abajo'  : 'Slide down';
  static String get animScaleUp   => isEs ? 'Ampliar'  : 'Zoom in';
  static String get animScaleDown => isEs ? 'Reducir'  : 'Zoom out';
  static String get animDuration  => isEs ? 'Duración' : 'Duration';
  static String get animOnScreenOn =>
      isEs ? 'Al encender la pantalla' : 'When screen wakes';
  static String get animOnUnlock =>
      isEs ? 'Al desbloquear' : 'When unlocked';
  static String get btnTestAnimIn =>
      isEs ? 'Vista previa: entrada' : 'Preview in';
  static String get btnTestAnimOut =>
      isEs ? 'Vista previa: salida' : 'Preview out';


  static String get colorSpectrum     => isEs ? 'Espectro'            : 'Spectrum';
  static String get materialYouAccents => isEs ? 'Colores de la foto' : 'Photo colors';
  static String get applyColor        => isEs ? 'Aplicar'             : 'Apply';


  static String get settingsHeader => isEs ? 'Ajustes' : 'Settings';
  static String get secLiveMusic =>
      isEs ? 'Música en reproducción' : 'Now playing';
  static String get liquidAlbumArtTitle =>
      isEs ? 'Carátula a pantalla completa' : 'Full-screen album art';
  static String get liquidAlbumArtSub => isEs
      ? 'Oculta el sujeto y adapta el color del reloj a la música en reproducción.'
      : 'Hides the subject and tints the clock to match current music.';
  static String get musicSyncActive   => isEs ? 'Activado'            : 'Active';
  static String get musicSyncRequired => isEs ? 'Permiso requerido'   : 'Permission required';
  static String get musicPermGrantedBtn =>
      isEs ? 'Administrar permisos' : 'Manage permissions';
  static String get musicPermGrantBtn =>
      isEs ? 'Permitir acceso a notificaciones' : 'Allow notification access';
  static String get targetMusicPlayer =>
      isEs ? 'Reproductor de música' : 'Music player';
  static String get playerAll =>
      isEs ? 'Todas las aplicaciones' : 'All apps';
  static String get secAppTheme => isEs ? 'Apariencia'   : 'Appearance';
  static String get themeDark   => isEs ? 'Modo oscuro'  : 'Dark mode';
  static String get themeLight  => isEs ? 'Modo claro'   : 'Light mode';
  static String get secLanguageHeader => isEs ? 'Idioma' : 'Language';
  static String get secClockDisplayHeader =>
      isEs ? 'Pantalla de inicio' : 'Home screen';
  static String get homescreenClock =>
      isEs ? 'Mostrar reloj en Inicio' : 'Show clock on Home screen';
  static String get homescreenClockSub => isEs
      ? 'Si se desactiva, el reloj solo se mostrará en la pantalla de bloqueo.'
      : 'When off, the clock only appears on the Lock screen.';
  static String get use24HourFormat =>
      isEs ? 'Formato de 24 horas' : '24-hour time';
  static String get use24HourFormatSub =>
      isEs ? '13:00 en lugar de 1:00 p. m.' : '13:00 instead of 1:00 PM';
  static String get secAboutHeader =>
      isEs ? 'Información' : 'About';
  static String get replayOnboarding =>
      isEs ? 'Ver guía de inicio' : 'View welcome guide';
  static String get versionLabel => isEs ? 'Versión' : 'Version';


  static String get skipBtn        => isEs ? 'Omitir'      : 'Skip';
  static String get nextBtn        => isEs ? 'Siguiente'   : 'Next';
  static String get enterStudioBtn => isEs ? 'Continuar'   : 'Continue';

  static String get onbSlide1Badge =>
      isEs ? 'Efecto de profundidad' : 'Depth Effect';
  static String get onbSlide1Title =>
      isEs ? 'Profundidad multicapa' : 'Multi-layer depth';
  static String get onbSlide1Sub => isEs
      ? 'Sitúe al sujeto de la foto delante del reloj para generar un efecto tridimensional.'
      : 'Place the photo subject in front of the clock to generate a 3D effect.';

  static String get onbSlide2Badge =>
      isEs ? 'Materiales de cristal' : 'Glass Materials';
  static String get onbSlide2Title =>
      isEs ? 'Cristal líquido óptico' : 'Optical liquid glass';
  static String get onbSlide2Sub => isEs
      ? 'Refracción en tiempo real, bordes especulares y desenfoque adaptativo.'
      : 'Real-time refraction, specular edges and adaptive backdrop blur.';

  static String get onbSlide3Badge =>
      isEs ? 'Sincronización en vivo' : 'Live Sync';
  static String get onbSlide3Title =>
      isEs ? 'Sincronizado con la reproducción' : 'Synced with playback';
  static String get onbSlide3Sub => isEs
      ? 'El fondo y el reloj se adaptan automáticamente a la carátula del álbum en reproducción.'
      : 'Background and clock adapt automatically to the now-playing album art.';

  static String get onbPermBadge => isEs ? 'Permisos' : 'Permissions';
  static String get onbPermTitle =>
      isEs ? 'Configuración de permisos' : 'Permission setup';
  static String get onbPermSub => isEs
      ? 'Conceda los accesos requeridos para cargar imágenes y sincronizar la reproducción.'
      : 'Grant the required accesses to load images and sync playback.';

  static String get onbStorageTitle =>
      isEs ? 'Fotos y vídeos' : 'Photos & videos';
  static String get onbStorageDesc => isEs
      ? 'Requerido para seleccionar imágenes de fondo y sujetos.'
      : 'Required to select background images and subjects.';
  static String get onbStorageGranted => isEs ? 'Permitido' : 'Allowed';
  static String get onbStorageAllow   => isEs ? 'Permitir'  : 'Allow';

  static String get onbMusicTitle =>
      isEs ? 'Acceso a notificaciones' : 'Notification access';
  static String get onbMusicDesc => isEs
      ? 'Requerido para mostrar la carátula del álbum en la pantalla de bloqueo.'
      : 'Required to display album art on the lock screen.';
  static String get onbMusicGranted => isEs ? 'Permitido' : 'Allowed';
  static String get onbMusicAllow   => isEs ? 'Permitir'  : 'Allow';

  static String get onbRestrictedTitle =>
      isEs ? 'Ajustes restringidos' : 'Restricted settings';
  static String get onbRestrictedDesc => isEs
      ? 'Abra Información de la aplicación, toque Más (⋮) y seleccione «Permitir ajustes restringidos».'
      : 'Open App info, tap More (⋮), and select "Allow restricted settings".';
  static String get onbOpenAppInfoBtn =>
      isEs ? 'Información de la aplicación' : 'App info';
}