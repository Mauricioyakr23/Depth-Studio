import '../../state/notifiers/app_notifiers.dart';

class StudioStrings {
  const StudioStrings._();

  static bool get _es => appLanguageNotifier.value == 'es';

  static String get studioTitle => _es ? 'Estudio' : 'Studio';
  static String get apply => _es ? 'Aplicar' : 'Apply';
  static String get reset => _es ? 'Restablecer' : 'Reset';
  static String get resetStudioTitle =>
      _es ? 'Restablecer diseño' : 'Reset design';
  static String get resetStudioDesc => _es
      ? 'Se eliminarán las fotos actuales y se restaurarán los valores predeterminados.'
      : 'Current photos will be removed and default values restored.';
  static String get bgRequiredTitle =>
      _es ? 'Fondo no seleccionado' : 'Background required';
  static String get bgRequiredDesc => _es
      ? 'Seleccione una foto de fondo antes de añadir un sujeto.'
      : 'Select a background photo before adding a subject.';
  static String get loadingBg => _es ? 'Cargando fondo…' : 'Loading background…';
  static String get loadingFg => _es ? 'Cargando sujeto…' : 'Loading subject…';
  static String get applyingWallpaper =>
      _es ? 'Aplicando fondo de pantalla…' : 'Applying wallpaper…';
  static String get noLayersLoaded =>
      _es ? 'Sin foto seleccionada' : 'No photo selected';
  static String get selectLayersBelow => _es
      ? 'Seleccione un fondo y un sujeto para comenzar.'
      : 'Select a background and subject to start.';

  static String get segBackground => _es ? 'Fondo' : 'Background';
  static String get segClock => _es ? 'Reloj' : 'Clock';
  static String get segDate => _es ? 'Fecha' : 'Date';
  static String get segMaterial => _es ? 'Efectos' : 'Effects';

  static String get secWallpaperLayers => _es ? 'Capas' : 'Layers';
  static String get btnStep1Bg => _es ? 'Fondo' : 'Background';
  static String get btnChangeBg => _es ? 'Cambiar fondo' : 'Change photo';
  static String get btnStep2Png => _es ? 'Sujeto' : 'Subject';
  static String get btnChangePng => _es ? 'Cambiar sujeto' : 'Change subject';
  static String get removeSubjectOverlay =>
      _es ? 'Eliminar sujeto' : 'Remove subject';

  static String get secDepth => _es ? 'Profundidad' : 'Depth';
  static String get depthLayering => _es ? 'Profundidad' : 'Depth';
  static String get layerStandard => _es ? 'Estándar' : 'Standard';
  static String get layerHoursFront => _es ? 'Horas del.' : 'Hours front';
  static String get layerMinutesFront => _es ? 'Minutos del.' : 'Min. front';

  static String get secBackgroundDim => _es ? 'Iluminación' : 'Lighting';
  static String get dimBackgroundLabel =>
      _es ? 'Atenuar fondo' : 'Dim background';

  static String get secClockPosition => _es ? 'Posición' : 'Position';
  static String get openPositionPicker =>
      _es ? 'Ajustar posición' : 'Adjust position';
  static String get openPositionPickerSub => _es
      ? 'Cuadrícula, preajustes y tamaño'
      : 'Grid, presets and size';
  static String get positionPickerTitle =>
      _es ? 'Posición del reloj' : 'Clock position';
  static String get sizeLabel => _es ? 'Tamaño' : 'Size';
  static String get presetsLabel => _es ? 'Preajustes' : 'Presets';
  static String get fineAdjustLabel => _es ? 'Ajuste fino' : 'Fine tuning';

  static String get secClockStructure => _es ? 'Disposición' : 'Layout';
  static String get clockDisplay => _es ? 'Alineación' : 'Alignment';
  static String get horizontal => _es ? 'Horizontal' : 'Horizontal';
  static String get vertical => _es ? 'Vertical' : 'Vertical';
  static String get clockStyle => _es ? 'Formato' : 'Format';

  static String get secTypeface => _es ? 'Tipografía' : 'Typeface';
  static String get addCustomFont => _es ? 'Importar' : 'Import';
  static String get customFontsHeader =>
      _es ? 'Tipografía personalizada' : 'Custom font';

  static String get secClockColor => _es ? 'Color' : 'Color';
  static String get separateMinutes =>
      _es ? 'Separar minutos' : 'Separate minutes';
  static String get clockUnifiedColor => _es ? 'Reloj' : 'Clock';
  static String get hourColor => _es ? 'Hora' : 'Hours';
  static String get minuteColor => _es ? 'Minutos' : 'Minutes';

  static String get secFontProportions => _es ? 'Proporciones' : 'Proportions';
  static String get letterSpacing => _es ? 'Espaciado' : 'Spacing';
  static String get verticalStretch =>
      _es ? 'Altura vertical' : 'Vertical height';
  static String get hoursMinutesGap =>
      _es ? 'Espacio entre líneas' : 'Line gap';

  static String get secDateVisibility => _es ? 'Visibilidad' : 'Visibility';
  static String get showDate => _es ? 'Mostrar fecha' : 'Show date';
  static String get uppercaseText => _es ? 'Mayúsculas' : 'Uppercase';
  static String get boldWeight => _es ? 'Negrita' : 'Bold';

  static String get secDatePosScale => _es ? 'Posición' : 'Position';
  static String get datePositionPickerTitle =>
      _es ? 'Posición de la fecha' : 'Date position';
  static String get openDatePositionPicker =>
      _es ? 'Ajustar fecha' : 'Adjust date';
  static String get openDatePositionPickerSub => _es
      ? 'Ubicación y tamaño en pantalla'
      : 'Placement and size on screen';

  static String get secDateFormat => _es ? 'Formato' : 'Format';
  static String get secDateColorAndFont =>
      _es ? 'Color y fuente' : 'Color & font';
  static String get secDateColor => _es ? 'Color' : 'Color';
  static String get secDateTypeface => _es ? 'Tipografía' : 'Typeface';
  static String get secDateMaterial => _es ? 'Material' : 'Material';

  static String get secSurfaceMaterial => _es ? 'Material' : 'Material';
  static String get matSolid => _es ? 'Sólido' : 'Solid';
  static String get matLiquid => _es ? 'Cristal' : 'Glass';
  static String get matAero => _es ? 'Mica' : 'Mica';
  static String get matAcrylic => _es ? 'Acrílico' : 'Acrylic';
  static String get backdropBlur => _es ? 'Desenfoque' : 'Blur';
  static String get glassBrightness => _es ? 'Brillo' : 'Brightness';
  static String get clockOpacity => _es ? 'Opacidad' : 'Opacity';
  static String get dateOpacity => _es ? 'Opacidad' : 'Opacity';
  static String get depthDropShadow => _es ? 'Sombra' : 'Shadow';

  static String get secGlassRim => _es ? 'Borde de cristal' : 'Glass edge';
  static String get enableGlassRim => _es ? 'Contorno' : 'Outline';
  static String get rimThickness => _es ? 'Grosor' : 'Thickness';
  static String get rimOpacity => _es ? 'Opacidad' : 'Opacity';
  static String get rimGlowBlur => _es ? 'Resplandor' : 'Glow';

  static String get secAnimStyle => _es ? 'Transición' : 'Transition';
  static String get animNone => _es ? 'Ninguna' : 'None';
  static String get animFade => _es ? 'Desvanecer' : 'Fade';
  static String get animSlideUp => _es ? 'Deslizar arriba' : 'Slide up';
  static String get animSlideDown => _es ? 'Deslizar abajo' : 'Slide down';
  static String get animScaleUp => _es ? 'Ampliar' : 'Zoom in';
  static String get animScaleDown => _es ? 'Reducir' : 'Zoom out';
  static String get animDuration => _es ? 'Duración' : 'Duration';
  static String get animOnScreenOn =>
      _es ? 'Al encender la pantalla' : 'When screen wakes';
  static String get animOnUnlock =>
      _es ? 'Al desbloquear' : 'When unlocked';
  static String get btnTestAnimIn =>
      _es ? 'Vista previa: entrada' : 'Preview in';
  static String get btnTestAnimOut =>
      _es ? 'Vista previa: salida' : 'Preview out';

  static String get colorSpectrum => _es ? 'Espectro' : 'Spectrum';
  static String get materialYouAccents =>
      _es ? 'Colores de la foto' : 'Photo colors';
  static String get applyColor => _es ? 'Aplicar' : 'Apply';

  static String get musicTitle => _es ? 'Música' : 'Music';
  static String get segMusicLayout => _es ? 'Posición' : 'Layout';
  static String get segMusicFonts => _es ? 'Fuentes' : 'Fonts';
  static String get segMusicMaterial => _es ? 'Material' : 'Material';
  static String get secMusicTarget => _es ? 'Elemento' : 'Element';
  static String get targetCover => _es ? 'Carátula' : 'Cover';
  static String get targetCard => _es ? 'Tarjeta' : 'Card';
  static String get targetClockDate => _es ? 'Reloj y fecha' : 'Clock & date';
  static String get horizontalPosLabel =>
      _es ? 'Posición horizontal' : 'Horizontal position';
  static String get verticalPosLabel =>
      _es ? 'Posición vertical' : 'Vertical position';
  static String get scaleLabel => _es ? 'Escala' : 'Scale';
  static String get secMusicClockFont =>
      _es ? 'Tipografía del reloj' : 'Clock typeface';
  static String get secMusicDateFont =>
      _es ? 'Tipografía de la fecha' : 'Date typeface';
  static String get secMusicCardFont =>
      _es ? 'Tipografía de la tarjeta' : 'Card typeface';
  static String get secMusicClockMaterial =>
      _es ? 'Material de reloj y fecha' : 'Clock & date material';
  static String get secMusicCardMaterial =>
      _es ? 'Material de la tarjeta' : 'Card material';
  static String get secMusicClockRim =>
      _es ? 'Borde de reloj y fecha' : 'Clock & date edge';
  static String get secMusicCardRim =>
      _es ? 'Borde de la tarjeta' : 'Card edge';
}