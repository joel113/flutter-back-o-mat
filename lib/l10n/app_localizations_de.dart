// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get saveNotes => 'Notizen speichern';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get sharedNotes => 'Gemeinsame Notizen';

  @override
  String get variantNotes => 'Notizen zur Variante';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get noteTitle => 'Titel der Notiz';

  @override
  String get noteBody => 'Hinweise und Beobachtungen';

  @override
  String get noteTitleRequired => 'Gib jeder Notiz einen Titel.';

  @override
  String get editSharedNotes => 'Gemeinsame Notizen bearbeiten';

  @override
  String get noNotes => 'Noch keine Notizen.';

  @override
  String get changeDescription => 'Änderungsbeschreibung (optional)';

  @override
  String get history => 'Versionsverlauf';

  @override
  String get sharedNotesHistory => 'Verlauf gemeinsamer Notizen';

  @override
  String get revisionPreview => 'Versionsvorschau';

  @override
  String get restoreRevision => 'Version wiederherstellen';

  @override
  String get restoreRevisionConfirm =>
      'Diesen Inhalt als neue Version wiederherstellen? Neuere Versionen bleiben erhalten.';

  @override
  String get restoredRevision => 'Wiederhergestellte Version';

  @override
  String get noRevisions => 'Noch keine Versionen.';

  @override
  String get revisionLoadError =>
      'Der Versionsverlauf konnte nicht geladen werden.';

  @override
  String get variantsLabel => 'Varianten';

  @override
  String get variantLabel => 'Variante';

  @override
  String get mainVariant => 'Hauptvariante';

  @override
  String get newVariant => 'Variante erstellen';

  @override
  String get variantName => 'Name der Variante';

  @override
  String get variantNameHint => 'Zum Beispiel: Übernachtgare';

  @override
  String get duplicateVariant =>
      'Wähle einen nichtleeren Variantennamen, der innerhalb dieses Brotes eindeutig ist.';

  @override
  String get makeMainVariant => 'Als Hauptvariante verwenden';

  @override
  String get renameFamily => 'Brotfamilie umbenennen';

  @override
  String get familyName => 'Name der Brotfamilie';

  @override
  String variantCount(int count) {
    return '$count Varianten';
  }

  @override
  String get familyLoadError =>
      'Die Rezeptvarianten konnten nicht geladen werden.';

  @override
  String get snapshotNotes => 'Mit diesem Backvorgang gespeicherte Notizen';

  @override
  String get create => 'Erstellen';

  @override
  String get reorderRecipes => 'Ziehen, um Rezepte umzusortieren';

  @override
  String get recipeOrderSaveError =>
      'Die Rezeptreihenfolge konnte nicht gespeichert werden. Die bisherige Reihenfolge wurde wiederhergestellt.';

  @override
  String get preparationsLabel => 'Vorbereitungsrezepte';

  @override
  String get addPreparation => 'Vorbereitungsrezept hinzufügen';

  @override
  String get choosePreparation => 'Vorbereitungsvariante auswählen';

  @override
  String get preparationConsumer => 'Benötigt im Schritt';

  @override
  String get invalidPreparations =>
      'Prüfe die Vorbereitungsrezepte: unterschiedliche vorhandene Varianten wählen, einem vorhandenen Schritt zuordnen und Kreisbezüge vermeiden.';

  @override
  String get preparationUnavailable =>
      'Nicht verfügbar: Rezept fehlt oder ist unvollständig. Du kannst ohne diese Vorbereitung fortfahren.';

  @override
  String get preparationChoiceHint =>
      'Wähle die für diesen Backvorgang nötigen Vorbereitungen. Lasse sie abgewählt, wenn z. B. dein Anstellgut schon bereit ist. Mengen werden unverändert übernommen.';

  @override
  String get preparationNestedHint =>
      'Dieses Vorbereitungsrezept hat eigene optionale Vorbereitungen. Diese werden in diesem Backvorgang nicht mitgeplant.';

  @override
  String get preparationsImportRemoved =>
      'Lokale Verknüpfungen zu Vorbereitungsrezepten wurden nicht importiert. Verknüpfe die Rezepte auf diesem Gerät erneut.';

  @override
  String get preparationLoadError =>
      'Vorbereitungsrezepte konnten nicht geladen werden.';

  @override
  String get continueBakingSetup => 'Weiter';

  @override
  String get preparationAddStagesFirst =>
      'Füge zuerst einen Backschritt hinzu, um eine Vorbereitung zuzuordnen.';

  @override
  String get noPreparationCandidates =>
      'Keine weiteren Rezeptvarianten vorhanden. Lege die Vorbereitung zuerst als separates Rezept an.';

  @override
  String get openPreparation => 'Vorbereitungsrezept öffnen';

  @override
  String get preparationNotSelected => 'Für diesen Backvorgang nicht nötig';

  @override
  String get preparationStartHint =>
      'Die gewählte Startzeit ist der Beginn aller Arbeiten einschließlich der Vorbereitungen. Unabhängige Brotschritte können parallel laufen.';

  @override
  String get preparationSnapshotHint =>
      'Gespeicherte Vorbereitungsrezepte und Notizen';

  @override
  String get importVariant => 'Variante aus Datei importieren';

  @override
  String get deleteVariant => 'Variante löschen';

  @override
  String get deleteVariantConfirm =>
      'Diese Variante und ihren Versionsverlauf löschen? Gespeicherte Backvorgänge bleiben erhalten.';

  @override
  String get lastVariantProtected =>
      'In dieser Brotfamilie muss mindestens eine Variante erhalten bleiben.';

  @override
  String get newMainVariant => 'Neue Hauptvariante';

  @override
  String get variantInUse =>
      'Diese Variante wird als Vorbereitungsrezept verwendet. Entferne oder ersetze zuerst die Verknüpfungen in diesen Rezepten:';

  @override
  String get variantDeleteError =>
      'Die Variante konnte nicht gelöscht werden. Es wurde nichts geändert.';

  @override
  String get title => 'Back-o-Mat';

  @override
  String get recipes => 'Rezepte';

  @override
  String get planer => 'Planer';

  @override
  String get info => 'Info';

  @override
  String get durationPickerTitle => 'Dauer auswählen';

  @override
  String get recipesLoadError => 'Rezepte konnten nicht geladen werden.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noRecipes => 'Noch keine Rezepte vorhanden.';

  @override
  String get startBaking => 'Backen starten';

  @override
  String get addRecipe => 'Rezept hinzufügen';

  @override
  String get manualRecipe => 'Manuell eingeben';

  @override
  String get importJson => 'JSON importieren';

  @override
  String get scanRecipe => 'Foto oder PDF scannen';

  @override
  String get editRecipe => 'Rezept bearbeiten';

  @override
  String get recipeName => 'Name';

  @override
  String get recipeDescription => 'Beschreibung';

  @override
  String get ingredientsLabel => 'Zutaten';

  @override
  String get stagesLabel => 'Backschritte';

  @override
  String get addIngredient => 'Zutat hinzufügen';

  @override
  String get addStage => 'Schritt hinzufügen';

  @override
  String get saveRecipe => 'Rezept speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get discardChanges => 'Ungespeicherte Änderungen verwerfen?';

  @override
  String get amountLabel => 'Menge (optional)';

  @override
  String get chooseUnit => 'Gängige Einheit auswählen';

  @override
  String get unitTeaspoon => 'TL';

  @override
  String get unitTablespoon => 'EL';

  @override
  String get unitPiece => 'Stück';

  @override
  String get unitPinch => 'Prise';

  @override
  String get durationMinimum => 'Mindestdauer';

  @override
  String get durationMaximum => 'Höchstdauer';

  @override
  String get timeUnit => 'Zeiteinheit';

  @override
  String get minutesUnit => 'Minuten';

  @override
  String get hoursUnit => 'Stunden';

  @override
  String get invalidDurationInput =>
      'Gib eine nichtnegative Dauer in ganzen Minuten ein, z. B. 1,5 Stunden.';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get conditionLabel => 'Zubereitungshinweise';

  @override
  String get durationMinLabel => 'Mindestdauer (Minuten)';

  @override
  String get durationMaxLabel => 'Höchstdauer (Minuten)';

  @override
  String get temperatureMinLabel => 'Mindesttemperatur (°C)';

  @override
  String get temperatureMaxLabel => 'Höchsttemperatur (°C)';

  @override
  String get addReference => 'Zutat oder vorherigen Schritt hinzufügen';

  @override
  String get referenceLabel => 'Zutat oder vorheriger Schritt';

  @override
  String get remove => 'Entfernen';

  @override
  String get moveUp => 'Nach oben';

  @override
  String get moveDown => 'Nach unten';

  @override
  String get chooseCover => 'Titelbild auswählen';

  @override
  String get removeCover => 'Titelbild entfernen';

  @override
  String get draftNotice =>
      'Entwurf: Zutaten, Schritte und Zeitangaben ergänzen, um zeitgesteuert zu backen.';

  @override
  String get nameRequired => 'Bitte einen Rezeptnamen eingeben.';

  @override
  String get labelsRequired =>
      'Jede Zutat und jeden Schritt benennen oder leere Einträge entfernen.';

  @override
  String get invalidReferences =>
      'Doppelte IDs, fehlende Verweise oder die Reihenfolge korrigieren. Schritte dürfen nur vorherige Schritte verwenden.';

  @override
  String get invalidQuantity => 'Mengen müssen nichtnegative Zahlen sein.';

  @override
  String get invalidDuration =>
      'Dauern müssen ganze, nichtnegative Minuten sein; die Höchstdauer darf nicht unter der Mindestdauer liegen.';

  @override
  String get invalidTemperature =>
      'Temperaturen müssen ganze Zahlen sein; die Höchsttemperatur darf nicht unter der Mindesttemperatur liegen.';

  @override
  String get saveError =>
      'Das Rezept konnte nicht gespeichert werden. Deine Änderungen bleiben erhalten.';

  @override
  String get importError =>
      'Die Datei konnte nicht importiert werden. Bitte gültiges Rezept-JSON, JPEG, PNG oder PDF auswählen.';

  @override
  String get duplicateName =>
      'Ein Rezept mit diesem Namen ist bereits vorhanden. Ein weiteres speichern?';

  @override
  String get saveAnother => 'Weiteres speichern';

  @override
  String get selectRecipe => 'Rezept zum Importieren auswählen';

  @override
  String get missingRecipe =>
      'Das Rezept konnte nicht gefunden oder geladen werden.';

  @override
  String get missingIngredients => 'Noch keine Zutaten eingetragen.';

  @override
  String get missingStages => 'Noch keine Backschritte eingetragen.';

  @override
  String get aiSettings => 'KI-Scan-Einstellungen';

  @override
  String get apiKeyLabel => 'OpenAI-API-Schlüssel';

  @override
  String get keyStored =>
      'Ein API-Schlüssel ist im macOS-Schlüsselbund gespeichert. Zum Ersetzen einen neuen Schlüssel eingeben.';

  @override
  String get saveKey => 'Schlüssel speichern';

  @override
  String get deleteKey => 'Gespeicherten Schlüssel entfernen';

  @override
  String get keyError => 'Zugriff auf den macOS-Schlüsselbund fehlgeschlagen.';

  @override
  String get keyRequired =>
      'Zuerst einen OpenAI-API-Schlüssel in den KI-Scan-Einstellungen hinterlegen.';

  @override
  String get extractRecipe => 'Rezept erkennen';

  @override
  String get chooseFiles => 'Dateien auswählen';

  @override
  String get scanDisclosure =>
      'Ausgewählte Dokumente werden beim Erkennen an OpenAI gesendet. Die API-Nutzung wird deinem OpenAI-Konto berechnet. Den erkannten Entwurf vor dem Speichern prüfen.';

  @override
  String get scanLimits =>
      'Ein PDF oder bis zu 10 JPEG-/PNG-Seiten eines Rezepts auswählen, insgesamt bis zu 20 MB. Bildseiten mit den Pfeilen anordnen.';

  @override
  String get scanBusy => 'Rezept wird erkannt…';

  @override
  String get scanReview =>
      'Erkannten Inhalt prüfen. Fehlende oder unklare Angaben bitte ergänzen.';

  @override
  String get scanAuthError =>
      'Der API-Schlüssel wurde abgelehnt. Bitte die KI-Scan-Einstellungen prüfen.';

  @override
  String get scanRateError =>
      'OpenAI-Anfragelimit oder Kontingent erreicht. API-Konto prüfen und später erneut versuchen.';

  @override
  String get scanNetworkError =>
      'Erkennung fehlgeschlagen oder Zeitlimit überschritten. Verbindung prüfen und erneut versuchen.';

  @override
  String get scanOutputError =>
      'Kein verwendbares Rezept erkannt. Ein deutlicheres Dokument versuchen oder das Rezept manuell eingeben.';

  @override
  String get scanFileError =>
      'Ein PDF oder bis zu 10 JPEG-/PNG-Bilder mit insgesamt höchstens 20 MB auswählen.';

  @override
  String get jsonReview =>
      'Importierten Inhalt vor dem Speichern prüfen. Schema.org-Zutatentext bleibt erhalten; Mengen, Zeiten und Schrittverweise bei Bedarf ergänzen.';

  @override
  String get stageColumn => 'Schritt';

  @override
  String get preparationColumn => 'Zutaten und Zubereitung';

  @override
  String get durationColumn => 'Dauer';

  @override
  String get temperatureColumn => 'Temperatur';

  @override
  String get planBake => 'Backvorgang planen';

  @override
  String get noBakes =>
      'Noch keine Backvorgänge. Füge ein Rezept hinzu, um den nächsten Backvorgang zu planen.';

  @override
  String get chooseBakingRecipe => 'Rezept auswählen';

  @override
  String get noReadyRecipes =>
      'Keine vollständigen Rezepte vorhanden. Ergänze zuerst Zutaten, Schritte und Zeiten in einem Rezept.';

  @override
  String get plannedStart => 'Geplanter Start';

  @override
  String get plannedEnd => 'Geplantes Ende';

  @override
  String get readyBetween => 'Fertig zwischen';

  @override
  String get sessionStatus => 'Status';

  @override
  String get bakePlanned => 'Geplant';

  @override
  String get bakeActive => 'In Arbeit';

  @override
  String get bakeCompleted => 'Abgeschlossen';

  @override
  String get stepPending => 'Nicht gestartet';

  @override
  String get stepRunning => 'Läuft';

  @override
  String get stepPaused => 'Pausiert';

  @override
  String get stepCompleted => 'Fertig';

  @override
  String get remainingTime => 'Verbleibend';

  @override
  String get startStep => 'Starten';

  @override
  String get pauseStep => 'Pausieren';

  @override
  String get resumeStep => 'Fortsetzen';

  @override
  String get completeStep => 'Als fertig markieren';

  @override
  String get waitingDependencies =>
      'Wartet darauf, dass vorherige Schritte als fertig markiert werden';

  @override
  String get actionsColumn => 'Aktionen';

  @override
  String get scheduleColumn => 'Start / Ende';

  @override
  String get durationTemperature => 'Dauer / Temperatur';

  @override
  String get changeStart => 'Startzeit ändern';

  @override
  String get chooseDuration => 'Dauer wählen';

  @override
  String get sessionSaveError =>
      'Der Backvorgang konnte nicht gespeichert werden. Der zuvor gespeicherte Stand bleibt erhalten. Bitte erneut versuchen.';

  @override
  String get sessionLoadError => 'Backvorgänge konnten nicht geladen werden.';

  @override
  String get saveSchedule => 'Speichern';

  @override
  String get removeBake => 'Backvorgang entfernen';

  @override
  String get removeBakeConfirm =>
      'Diesen Backvorgang und seinen Fortschritt entfernen? Das Rezept bleibt erhalten.';

  @override
  String get scheduleHint =>
      'Schritte ohne Verweise auf frühere Schritte laufen parallel. Eine gewählte Startzeit ist der früheste Start; Abhängigkeiten können ihn nach hinten verschieben. Timer laufen beim Verlassen der Ansicht nach Uhrzeit weiter.';

  @override
  String get recipeSnapshot =>
      'Dieser Backvorgang verwendet eine gespeicherte Rezeptkopie. Rezeptänderungen gelten für neue Backvorgänge.';

  @override
  String get overdue => 'Zeit abgelaufen — Schritt prüfen';

  @override
  String get durationRangeError =>
      'Wähle ganze Minuten innerhalb des im Rezept angegebenen Zeitbereichs.';

  @override
  String get openBake => 'Backvorgang öffnen';

  @override
  String get sessionStartLabel => 'Beginn des Backvorgangs';

  @override
  String get actualStart => 'Tatsächlicher Start';

  @override
  String get actualEnd => 'Tatsächliches Ende';

  @override
  String get timelineTitle => 'Zeitplan';

  @override
  String get tableView => 'Tabelle';

  @override
  String get timelineDragHint =>
      'Balken verschieben, um den Schritt zu verlegen. Am rechten Rand die Dauer im erlaubten Bereich ändern. Doppelklick für eine genaue Startzeit. Esc bricht das Ziehen ab.';

  @override
  String get timelineResizeHint =>
      'Ziehen zum Ändern der Dauer; klicken für genaue Minuten';

  @override
  String get timelineLocked =>
      'Gestartete Schritte sind gegen Verschieben und Größenänderung gesperrt.';

  @override
  String get timelineFit => 'Einpassen';

  @override
  String get timelineZoomIn => 'Vergrößern';

  @override
  String get timelineZoomOut => 'Verkleinern';

  @override
  String get timelineEarlier => 'Früher';

  @override
  String get timelineLater => 'Später';

  @override
  String get bakingHelp => 'Hinweise zum Backzeitplan';

  @override
  String dependencyWaiting(
    String predecessor,
    String successor,
    String duration,
  ) {
    return '$predecessor ist $duration vor dem Beginn von $successor fertig.';
  }

  @override
  String dependencyTooEarly(
    String predecessor,
    String successor,
    String duration,
    String excess,
  ) {
    return '$predecessor ist $duration vor der Verwendung in $successor fertig; die maximale Rezeptdauer wird um $excess überschritten. Bitte diese Wartezeit prüfen.';
  }

  @override
  String dependencyConflict(
    String predecessor,
    String successor,
    String duration,
  ) {
    return '$successor beginnt $duration, bevor $predecessor fertig ist. Tatsächliche Schrittzeiten bleiben unverändert.';
  }

  @override
  String get timingWarningsTitle => 'Verbundene Schritte prüfen';

  @override
  String get timingWaitingTitle => 'Wartezeiten zwischen Schritten';

  @override
  String get timelineConnectionLegend =>
      'Gestrichelte Verbindungen zeigen Wartezeiten. Gelbe oder rote Verbindungen bitte prüfen. Hervorgehobene Balken folgen dem geänderten Schritt.';

  @override
  String get timelineAffected =>
      'Wird mit dem geänderten Schritt neu berechnet';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsSubtitle => 'Alles für deinen nächsten Backtag.';

  @override
  String get recipesSubtitle => 'Deine Rezepte für den nächsten Backtag.';

  @override
  String get plannerSubtitle =>
      'Deine Backvorgänge und die nächsten Schritte im Blick.';

  @override
  String get aiSettingsDescription =>
      'Verwalte deinen persönlichen OpenAI-API-Schlüssel für den Rezeptimport aus Fotos und PDFs.';

  @override
  String get appearance => 'Darstellung';

  @override
  String get systemAppearance =>
      'Die helle oder dunkle Darstellung folgt deinen Systemeinstellungen.';

  @override
  String get aboutApp => 'Über Back-o-Mat';

  @override
  String get aboutDescription =>
      'Brotrezepte, durchdachte Planung und etwas mehr Ruhe am Backtag. Deine Rezepte und Backfortschritte werden auf diesem Gerät gespeichert.';
}
