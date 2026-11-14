// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get saveNotes => 'Save notes';

  @override
  String get notesLabel => 'Notes';

  @override
  String get sharedNotes => 'Shared notes';

  @override
  String get variantNotes => 'Variant notes';

  @override
  String get addNote => 'Add note';

  @override
  String get noteTitle => 'Note title';

  @override
  String get noteBody => 'Notes and observations';

  @override
  String get noteTitleRequired => 'Give every note a title.';

  @override
  String get editSharedNotes => 'Edit shared notes';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get changeDescription => 'Change description (optional)';

  @override
  String get history => 'Revision history';

  @override
  String get sharedNotesHistory => 'Shared notes history';

  @override
  String get revisionPreview => 'Revision preview';

  @override
  String get restoreRevision => 'Restore revision';

  @override
  String get restoreRevisionConfirm =>
      'Restore this content as a new revision? Later revisions remain available.';

  @override
  String get restoredRevision => 'Restored revision';

  @override
  String get noRevisions => 'No revisions yet.';

  @override
  String get revisionLoadError => 'Could not load revision history.';

  @override
  String get variantsLabel => 'Variants';

  @override
  String get variantLabel => 'Variant';

  @override
  String get mainVariant => 'Main variant';

  @override
  String get newVariant => 'Create variant';

  @override
  String get variantName => 'Variant name';

  @override
  String get variantNameHint => 'For example: overnight proof';

  @override
  String get duplicateVariant =>
      'Choose a non-empty variant name that is unique within this bread.';

  @override
  String get makeMainVariant => 'Use as main variant';

  @override
  String get renameFamily => 'Rename bread family';

  @override
  String get familyName => 'Bread family name';

  @override
  String variantCount(int count) {
    return '$count variants';
  }

  @override
  String get familyLoadError => 'Could not load recipe variants.';

  @override
  String get snapshotNotes => 'Notes saved with this bake';

  @override
  String get create => 'Create';

  @override
  String get reorderRecipes => 'Drag to reorder recipes';

  @override
  String get recipeOrderSaveError =>
      'Could not save the recipe order. The previous order has been restored.';

  @override
  String get preparationsLabel => 'Preparation recipes';

  @override
  String get addPreparation => 'Attach preparation recipe';

  @override
  String get choosePreparation => 'Choose a preparation variant';

  @override
  String get preparationConsumer => 'Required by step';

  @override
  String get invalidPreparations =>
      'Check preparation links: use different existing variants, assign an existing step, and avoid circular dependencies.';

  @override
  String get preparationUnavailable =>
      'Unavailable: recipe is missing or incomplete. You can continue without it.';

  @override
  String get preparationChoiceHint =>
      'Select preparations needed for this bake. Leave them unchecked if, for example, your starter is already ready. Quantities are used as written.';

  @override
  String get preparationNestedHint =>
      'This preparation has its own optional preparations. Those are not included in this bake.';

  @override
  String get preparationsImportRemoved =>
      'Local preparation links were not imported. Attach the preparation recipes again on this device.';

  @override
  String get preparationLoadError => 'Could not load preparation recipes.';

  @override
  String get continueBakingSetup => 'Continue';

  @override
  String get preparationAddStagesFirst =>
      'Add a baking step before attaching preparation.';

  @override
  String get noPreparationCandidates =>
      'No other recipe variants available. Create the preparation as a separate recipe first.';

  @override
  String get openPreparation => 'Open preparation recipe';

  @override
  String get preparationNotSelected => 'Not needed for this bake';

  @override
  String get preparationStartHint =>
      'The selected start is the beginning of all work, including preparations. Independent bread steps can run in parallel.';

  @override
  String get preparationSnapshotHint => 'Saved preparation recipes and notes';

  @override
  String get importVariant => 'Import variant from file';

  @override
  String get deleteVariant => 'Delete variant';

  @override
  String get deleteVariantConfirm =>
      'Delete this variant and its revision history? Saved baking sessions remain available.';

  @override
  String get lastVariantProtected =>
      'At least one variant must remain in this bread family.';

  @override
  String get newMainVariant => 'New main variant';

  @override
  String get variantInUse =>
      'This variant is used as a preparation recipe. Remove or replace its links in these recipes first:';

  @override
  String get variantDeleteError =>
      'Could not delete the variant. Nothing was changed.';

  @override
  String get title => 'Back-o-Mat';

  @override
  String get recipes => 'Recipes';

  @override
  String get planer => 'Planner';

  @override
  String get info => 'Info';

  @override
  String get durationPickerTitle => 'Select duration';

  @override
  String get recipesLoadError => 'Could not load recipes.';

  @override
  String get retry => 'Retry';

  @override
  String get noRecipes => 'No recipes yet.';

  @override
  String get startBaking => 'Start baking';

  @override
  String get addRecipe => 'Add recipe';

  @override
  String get manualRecipe => 'Enter manually';

  @override
  String get importJson => 'Import JSON';

  @override
  String get scanRecipe => 'Scan photo or PDF';

  @override
  String get editRecipe => 'Edit recipe';

  @override
  String get recipeName => 'Name';

  @override
  String get recipeDescription => 'Description';

  @override
  String get ingredientsLabel => 'Ingredients';

  @override
  String get stagesLabel => 'Baking stages';

  @override
  String get addIngredient => 'Add ingredient';

  @override
  String get addStage => 'Add stage';

  @override
  String get saveRecipe => 'Save recipe';

  @override
  String get cancel => 'Cancel';

  @override
  String get discard => 'Discard';

  @override
  String get discardChanges => 'Discard unsaved changes?';

  @override
  String get amountLabel => 'Quantity (optional)';

  @override
  String get chooseUnit => 'Choose a common unit';

  @override
  String get unitTeaspoon => 'tsp';

  @override
  String get unitTablespoon => 'tbsp';

  @override
  String get unitPiece => 'piece';

  @override
  String get unitPinch => 'pinch';

  @override
  String get durationMinimum => 'Minimum duration';

  @override
  String get durationMaximum => 'Maximum duration';

  @override
  String get timeUnit => 'Time unit';

  @override
  String get minutesUnit => 'Minutes';

  @override
  String get hoursUnit => 'Hours';

  @override
  String get invalidDurationInput =>
      'Enter a non-negative duration in whole minutes, e.g. 1.5 hours.';

  @override
  String get unitLabel => 'Unit';

  @override
  String get conditionLabel => 'Preparation notes';

  @override
  String get durationMinLabel => 'Minimum duration (minutes)';

  @override
  String get durationMaxLabel => 'Maximum duration (minutes)';

  @override
  String get temperatureMinLabel => 'Minimum temperature (°C)';

  @override
  String get temperatureMaxLabel => 'Maximum temperature (°C)';

  @override
  String get addReference => 'Add ingredient or earlier stage';

  @override
  String get referenceLabel => 'Ingredient or earlier stage';

  @override
  String get remove => 'Remove';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get chooseCover => 'Choose cover image';

  @override
  String get removeCover => 'Remove cover image';

  @override
  String get draftNotice =>
      'Draft: add ingredients, stages, and stage timings to enable timed baking.';

  @override
  String get nameRequired => 'Enter a recipe name.';

  @override
  String get labelsRequired =>
      'Give every ingredient and stage a name, or remove empty entries.';

  @override
  String get invalidReferences =>
      'Fix duplicate IDs, missing references, or stage order. Stages can only use earlier stages.';

  @override
  String get invalidQuantity => 'Quantities must be non-negative numbers.';

  @override
  String get invalidDuration =>
      'Durations must be whole, non-negative minutes; maximum must not be below minimum.';

  @override
  String get invalidTemperature =>
      'Temperatures must be whole numbers; maximum must not be below minimum.';

  @override
  String get saveError =>
      'Could not save the recipe. Your changes are still here.';

  @override
  String get importError =>
      'Could not import this file. Select a valid recipe JSON, JPEG, PNG, or PDF.';

  @override
  String get duplicateName =>
      'A recipe with this name already exists. Save another recipe?';

  @override
  String get saveAnother => 'Save another';

  @override
  String get selectRecipe => 'Select a recipe to import';

  @override
  String get missingRecipe => 'The recipe could not be found or loaded.';

  @override
  String get missingIngredients => 'No ingredients entered yet.';

  @override
  String get missingStages => 'No baking stages entered yet.';

  @override
  String get aiSettings => 'AI scanning settings';

  @override
  String get apiKeyLabel => 'OpenAI API key';

  @override
  String get keyStored =>
      'An API key is stored in macOS Keychain. Enter a new key to replace it.';

  @override
  String get saveKey => 'Save key';

  @override
  String get deleteKey => 'Remove stored key';

  @override
  String get keyError => 'Could not access macOS Keychain.';

  @override
  String get keyRequired =>
      'Add an OpenAI API key in AI scanning settings first.';

  @override
  String get extractRecipe => 'Extract recipe';

  @override
  String get chooseFiles => 'Choose files';

  @override
  String get scanDisclosure =>
      'Selected documents will be sent to OpenAI when you choose Extract recipe. API usage is billed to your OpenAI account. Review the extracted draft before saving.';

  @override
  String get scanLimits =>
      'Select one PDF or up to 10 JPEG/PNG pages of one recipe, up to 20 MB in total. Use the arrows to arrange image pages.';

  @override
  String get scanBusy => 'Extracting recipe…';

  @override
  String get scanReview =>
      'Review the extracted content. Missing or unclear information has been left for you to complete.';

  @override
  String get scanAuthError =>
      'The API key was rejected. Check AI scanning settings.';

  @override
  String get scanRateError =>
      'OpenAI rate limit or quota reached. Check your API account and try again later.';

  @override
  String get scanNetworkError =>
      'Extraction failed or timed out. Check your connection and try again.';

  @override
  String get scanOutputError =>
      'No usable recipe was returned. Try a clearer document or enter the recipe manually.';

  @override
  String get scanFileError =>
      'Choose one PDF or up to 10 JPEG/PNG images, no more than 20 MB in total.';

  @override
  String get jsonReview =>
      'Review imported content before saving. Schema.org ingredient text is preserved; fill in quantities, timings, and stage references as needed.';

  @override
  String get stageColumn => 'Step';

  @override
  String get preparationColumn => 'Ingredients and preparation';

  @override
  String get durationColumn => 'Duration';

  @override
  String get temperatureColumn => 'Temperature';

  @override
  String get planBake => 'Plan a bake';

  @override
  String get noBakes =>
      'No baking sessions yet. Add a recipe to plan your next bake.';

  @override
  String get chooseBakingRecipe => 'Choose a recipe';

  @override
  String get noReadyRecipes =>
      'No complete recipes available. Add ingredients, stages, and timings to a recipe first.';

  @override
  String get plannedStart => 'Planned start';

  @override
  String get plannedEnd => 'Planned end';

  @override
  String get readyBetween => 'Ready between';

  @override
  String get sessionStatus => 'Status';

  @override
  String get bakePlanned => 'Planned';

  @override
  String get bakeActive => 'In progress';

  @override
  String get bakeCompleted => 'Completed';

  @override
  String get stepPending => 'Not started';

  @override
  String get stepRunning => 'Running';

  @override
  String get stepPaused => 'Paused';

  @override
  String get stepCompleted => 'Done';

  @override
  String get remainingTime => 'Remaining';

  @override
  String get startStep => 'Start';

  @override
  String get pauseStep => 'Pause';

  @override
  String get resumeStep => 'Resume';

  @override
  String get completeStep => 'Mark done';

  @override
  String get waitingDependencies =>
      'Waiting for earlier stages to be marked done';

  @override
  String get actionsColumn => 'Actions';

  @override
  String get scheduleColumn => 'Start / end';

  @override
  String get durationTemperature => 'Duration / temperature';

  @override
  String get changeStart => 'Change start time';

  @override
  String get chooseDuration => 'Choose duration';

  @override
  String get sessionSaveError =>
      'Could not save the baking session. The previous saved state is unchanged. Please retry.';

  @override
  String get sessionLoadError => 'Could not load baking sessions.';

  @override
  String get saveSchedule => 'Save';

  @override
  String get removeBake => 'Remove baking session';

  @override
  String get removeBakeConfirm =>
      'Remove this baking session and its progress? The recipe will be kept.';

  @override
  String get scheduleHint =>
      'Stages without earlier-stage references run in parallel. A chosen start time is the earliest allowed start; dependencies can move it later. Timers continue by clock time when you leave the view.';

  @override
  String get recipeSnapshot =>
      'This bake uses a saved recipe snapshot. Recipe edits apply to new baking sessions.';

  @override
  String get overdue => 'Time elapsed — check this step';

  @override
  String get durationRangeError =>
      'Choose whole minutes within the recipe’s duration range.';

  @override
  String get openBake => 'Open baking session';

  @override
  String get sessionStartLabel => 'Session start';

  @override
  String get actualStart => 'Actual start';

  @override
  String get actualEnd => 'Actual end';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get tableView => 'Table';

  @override
  String get timelineDragHint =>
      'Drag a bar to move the step. Drag its right edge to change duration within the allowed range. Double-click for an exact start time. Esc cancels a drag.';

  @override
  String get timelineResizeHint =>
      'Drag to change duration; click for exact minutes';

  @override
  String get timelineLocked =>
      'Started steps are locked against moving or resizing.';

  @override
  String get timelineFit => 'Fit';

  @override
  String get timelineZoomIn => 'Zoom in';

  @override
  String get timelineZoomOut => 'Zoom out';

  @override
  String get timelineEarlier => 'Earlier';

  @override
  String get timelineLater => 'Later';

  @override
  String get bakingHelp => 'About this baking schedule';

  @override
  String dependencyWaiting(
    String predecessor,
    String successor,
    String duration,
  ) {
    return '$predecessor is ready $duration before $successor starts.';
  }

  @override
  String dependencyTooEarly(
    String predecessor,
    String successor,
    String duration,
    String excess,
  ) {
    return '$predecessor is ready $duration before use in $successor; the recipe’s maximum duration is exceeded by $excess. Review this waiting time.';
  }

  @override
  String dependencyConflict(
    String predecessor,
    String successor,
    String duration,
  ) {
    return '$successor starts $duration before $predecessor is ready. Actual step times remain unchanged.';
  }

  @override
  String get timingWarningsTitle => 'Check connected steps';

  @override
  String get timingWaitingTitle => 'Waiting between steps';

  @override
  String get timelineConnectionLegend =>
      'Dashed links show waiting. Amber or red links need review. Highlighted bars follow the step being changed.';

  @override
  String get timelineAffected => 'Recalculated with the changed step';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Make room for your next good bake.';

  @override
  String get recipesSubtitle => 'Your recipes, ready for the next bake.';

  @override
  String get plannerSubtitle =>
      'A clear view of what is baking and what comes next.';

  @override
  String get aiSettingsDescription =>
      'Manage your personal OpenAI API key for photo and PDF recipe imports.';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemAppearance =>
      'Light and dark appearance follows your system settings.';

  @override
  String get aboutApp => 'About Back-o-Mat';

  @override
  String get aboutDescription =>
      'Bread recipes, thoughtful planning, and a little more calm on baking day. Your recipes and baking progress are stored on this device.';
}
