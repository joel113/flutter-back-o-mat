import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @saveNotes.
  ///
  /// In en, this message translates to:
  /// **'Save notes'**
  String get saveNotes;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @sharedNotes.
  ///
  /// In en, this message translates to:
  /// **'Shared notes'**
  String get sharedNotes;

  /// No description provided for @variantNotes.
  ///
  /// In en, this message translates to:
  /// **'Variant notes'**
  String get variantNotes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteTitle;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'Notes and observations'**
  String get noteBody;

  /// No description provided for @noteTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give every note a title.'**
  String get noteTitleRequired;

  /// No description provided for @editSharedNotes.
  ///
  /// In en, this message translates to:
  /// **'Edit shared notes'**
  String get editSharedNotes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @changeDescription.
  ///
  /// In en, this message translates to:
  /// **'Change description (optional)'**
  String get changeDescription;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Revision history'**
  String get history;

  /// No description provided for @sharedNotesHistory.
  ///
  /// In en, this message translates to:
  /// **'Shared notes history'**
  String get sharedNotesHistory;

  /// No description provided for @revisionPreview.
  ///
  /// In en, this message translates to:
  /// **'Revision preview'**
  String get revisionPreview;

  /// No description provided for @restoreRevision.
  ///
  /// In en, this message translates to:
  /// **'Restore revision'**
  String get restoreRevision;

  /// No description provided for @restoreRevisionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore this content as a new revision? Later revisions remain available.'**
  String get restoreRevisionConfirm;

  /// No description provided for @restoredRevision.
  ///
  /// In en, this message translates to:
  /// **'Restored revision'**
  String get restoredRevision;

  /// No description provided for @noRevisions.
  ///
  /// In en, this message translates to:
  /// **'No revisions yet.'**
  String get noRevisions;

  /// No description provided for @revisionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load revision history.'**
  String get revisionLoadError;

  /// No description provided for @variantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get variantsLabel;

  /// No description provided for @variantLabel.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variantLabel;

  /// No description provided for @mainVariant.
  ///
  /// In en, this message translates to:
  /// **'Main variant'**
  String get mainVariant;

  /// No description provided for @newVariant.
  ///
  /// In en, this message translates to:
  /// **'Create variant'**
  String get newVariant;

  /// No description provided for @variantName.
  ///
  /// In en, this message translates to:
  /// **'Variant name'**
  String get variantName;

  /// No description provided for @variantNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: overnight proof'**
  String get variantNameHint;

  /// No description provided for @duplicateVariant.
  ///
  /// In en, this message translates to:
  /// **'Choose a non-empty variant name that is unique within this bread.'**
  String get duplicateVariant;

  /// No description provided for @makeMainVariant.
  ///
  /// In en, this message translates to:
  /// **'Use as main variant'**
  String get makeMainVariant;

  /// No description provided for @renameFamily.
  ///
  /// In en, this message translates to:
  /// **'Rename bread family'**
  String get renameFamily;

  /// No description provided for @familyName.
  ///
  /// In en, this message translates to:
  /// **'Bread family name'**
  String get familyName;

  /// No description provided for @variantCount.
  ///
  /// In en, this message translates to:
  /// **'{count} variants'**
  String variantCount(int count);

  /// No description provided for @familyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recipe variants.'**
  String get familyLoadError;

  /// No description provided for @snapshotNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes saved with this bake'**
  String get snapshotNotes;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @reorderRecipes.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder recipes'**
  String get reorderRecipes;

  /// No description provided for @recipeOrderSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the recipe order. The previous order has been restored.'**
  String get recipeOrderSaveError;

  /// No description provided for @preparationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation recipes'**
  String get preparationsLabel;

  /// No description provided for @addPreparation.
  ///
  /// In en, this message translates to:
  /// **'Attach preparation recipe'**
  String get addPreparation;

  /// No description provided for @choosePreparation.
  ///
  /// In en, this message translates to:
  /// **'Choose a preparation variant'**
  String get choosePreparation;

  /// No description provided for @preparationConsumer.
  ///
  /// In en, this message translates to:
  /// **'Required by step'**
  String get preparationConsumer;

  /// No description provided for @invalidPreparations.
  ///
  /// In en, this message translates to:
  /// **'Check preparation links: use different existing variants, assign an existing step, and avoid circular dependencies.'**
  String get invalidPreparations;

  /// No description provided for @preparationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: recipe is missing or incomplete. You can continue without it.'**
  String get preparationUnavailable;

  /// No description provided for @preparationChoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Select preparations needed for this bake. Leave them unchecked if, for example, your starter is already ready. Quantities are used as written.'**
  String get preparationChoiceHint;

  /// No description provided for @preparationNestedHint.
  ///
  /// In en, this message translates to:
  /// **'This preparation has its own optional preparations. Those are not included in this bake.'**
  String get preparationNestedHint;

  /// No description provided for @preparationsImportRemoved.
  ///
  /// In en, this message translates to:
  /// **'Local preparation links were not imported. Attach the preparation recipes again on this device.'**
  String get preparationsImportRemoved;

  /// No description provided for @preparationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load preparation recipes.'**
  String get preparationLoadError;

  /// No description provided for @continueBakingSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBakingSetup;

  /// No description provided for @preparationAddStagesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a baking step before attaching preparation.'**
  String get preparationAddStagesFirst;

  /// No description provided for @noPreparationCandidates.
  ///
  /// In en, this message translates to:
  /// **'No other recipe variants available. Create the preparation as a separate recipe first.'**
  String get noPreparationCandidates;

  /// No description provided for @openPreparation.
  ///
  /// In en, this message translates to:
  /// **'Open preparation recipe'**
  String get openPreparation;

  /// No description provided for @preparationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not needed for this bake'**
  String get preparationNotSelected;

  /// No description provided for @preparationStartHint.
  ///
  /// In en, this message translates to:
  /// **'The selected start is the beginning of all work, including preparations. Independent bread steps can run in parallel.'**
  String get preparationStartHint;

  /// No description provided for @preparationSnapshotHint.
  ///
  /// In en, this message translates to:
  /// **'Saved preparation recipes and notes'**
  String get preparationSnapshotHint;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Back-o-Mat'**
  String get title;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @planer.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get planer;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @durationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select duration'**
  String get durationPickerTitle;

  /// No description provided for @recipesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recipes.'**
  String get recipesLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet.'**
  String get noRecipes;

  /// No description provided for @startBaking.
  ///
  /// In en, this message translates to:
  /// **'Start baking'**
  String get startBaking;

  /// No description provided for @addRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add recipe'**
  String get addRecipe;

  /// No description provided for @manualRecipe.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get manualRecipe;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @scanRecipe.
  ///
  /// In en, this message translates to:
  /// **'Scan photo or PDF'**
  String get scanRecipe;

  /// No description provided for @editRecipe.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get editRecipe;

  /// No description provided for @recipeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get recipeName;

  /// No description provided for @recipeDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get recipeDescription;

  /// No description provided for @ingredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsLabel;

  /// No description provided for @stagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Baking stages'**
  String get stagesLabel;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get addIngredient;

  /// No description provided for @addStage.
  ///
  /// In en, this message translates to:
  /// **'Add stage'**
  String get addStage;

  /// No description provided for @saveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get saveRecipe;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discardChanges;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity (optional)'**
  String get amountLabel;

  /// No description provided for @chooseUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose a common unit'**
  String get chooseUnit;

  /// No description provided for @unitTeaspoon.
  ///
  /// In en, this message translates to:
  /// **'tsp'**
  String get unitTeaspoon;

  /// No description provided for @unitTablespoon.
  ///
  /// In en, this message translates to:
  /// **'tbsp'**
  String get unitTablespoon;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get unitPiece;

  /// No description provided for @unitPinch.
  ///
  /// In en, this message translates to:
  /// **'pinch'**
  String get unitPinch;

  /// No description provided for @durationMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration'**
  String get durationMinimum;

  /// No description provided for @durationMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum duration'**
  String get durationMaximum;

  /// No description provided for @timeUnit.
  ///
  /// In en, this message translates to:
  /// **'Time unit'**
  String get timeUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesUnit;

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursUnit;

  /// No description provided for @invalidDurationInput.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative duration in whole minutes, e.g. 1.5 hours.'**
  String get invalidDurationInput;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation notes'**
  String get conditionLabel;

  /// No description provided for @durationMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration (minutes)'**
  String get durationMinLabel;

  /// No description provided for @durationMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum duration (minutes)'**
  String get durationMaxLabel;

  /// No description provided for @temperatureMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum temperature (°C)'**
  String get temperatureMinLabel;

  /// No description provided for @temperatureMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum temperature (°C)'**
  String get temperatureMaxLabel;

  /// No description provided for @addReference.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient or earlier stage'**
  String get addReference;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredient or earlier stage'**
  String get referenceLabel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @chooseCover.
  ///
  /// In en, this message translates to:
  /// **'Choose cover image'**
  String get chooseCover;

  /// No description provided for @removeCover.
  ///
  /// In en, this message translates to:
  /// **'Remove cover image'**
  String get removeCover;

  /// No description provided for @draftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft: add ingredients, stages, and stage timings to enable timed baking.'**
  String get draftNotice;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a recipe name.'**
  String get nameRequired;

  /// No description provided for @labelsRequired.
  ///
  /// In en, this message translates to:
  /// **'Give every ingredient and stage a name, or remove empty entries.'**
  String get labelsRequired;

  /// No description provided for @invalidReferences.
  ///
  /// In en, this message translates to:
  /// **'Fix duplicate IDs, missing references, or stage order. Stages can only use earlier stages.'**
  String get invalidReferences;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantities must be non-negative numbers.'**
  String get invalidQuantity;

  /// No description provided for @invalidDuration.
  ///
  /// In en, this message translates to:
  /// **'Durations must be whole, non-negative minutes; maximum must not be below minimum.'**
  String get invalidDuration;

  /// No description provided for @invalidTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperatures must be whole numbers; maximum must not be below minimum.'**
  String get invalidTemperature;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the recipe. Your changes are still here.'**
  String get saveError;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Could not import this file. Select a valid recipe JSON, JPEG, PNG, or PDF.'**
  String get importError;

  /// No description provided for @duplicateName.
  ///
  /// In en, this message translates to:
  /// **'A recipe with this name already exists. Save another recipe?'**
  String get duplicateName;

  /// No description provided for @saveAnother.
  ///
  /// In en, this message translates to:
  /// **'Save another'**
  String get saveAnother;

  /// No description provided for @selectRecipe.
  ///
  /// In en, this message translates to:
  /// **'Select a recipe to import'**
  String get selectRecipe;

  /// No description provided for @missingRecipe.
  ///
  /// In en, this message translates to:
  /// **'The recipe could not be found or loaded.'**
  String get missingRecipe;

  /// No description provided for @missingIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredients entered yet.'**
  String get missingIngredients;

  /// No description provided for @missingStages.
  ///
  /// In en, this message translates to:
  /// **'No baking stages entered yet.'**
  String get missingStages;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI scanning settings'**
  String get aiSettings;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key'**
  String get apiKeyLabel;

  /// No description provided for @keyStored.
  ///
  /// In en, this message translates to:
  /// **'An API key is stored in macOS Keychain. Enter a new key to replace it.'**
  String get keyStored;

  /// No description provided for @saveKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get saveKey;

  /// No description provided for @deleteKey.
  ///
  /// In en, this message translates to:
  /// **'Remove stored key'**
  String get deleteKey;

  /// No description provided for @keyError.
  ///
  /// In en, this message translates to:
  /// **'Could not access macOS Keychain.'**
  String get keyError;

  /// No description provided for @keyRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an OpenAI API key in AI scanning settings first.'**
  String get keyRequired;

  /// No description provided for @extractRecipe.
  ///
  /// In en, this message translates to:
  /// **'Extract recipe'**
  String get extractRecipe;

  /// No description provided for @chooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get chooseFiles;

  /// No description provided for @scanDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Selected documents will be sent to OpenAI when you choose Extract recipe. API usage is billed to your OpenAI account. Review the extracted draft before saving.'**
  String get scanDisclosure;

  /// No description provided for @scanLimits.
  ///
  /// In en, this message translates to:
  /// **'Select one PDF or up to 10 JPEG/PNG pages of one recipe, up to 20 MB in total. Use the arrows to arrange image pages.'**
  String get scanLimits;

  /// No description provided for @scanBusy.
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe…'**
  String get scanBusy;

  /// No description provided for @scanReview.
  ///
  /// In en, this message translates to:
  /// **'Review the extracted content. Missing or unclear information has been left for you to complete.'**
  String get scanReview;

  /// No description provided for @scanAuthError.
  ///
  /// In en, this message translates to:
  /// **'The API key was rejected. Check AI scanning settings.'**
  String get scanAuthError;

  /// No description provided for @scanRateError.
  ///
  /// In en, this message translates to:
  /// **'OpenAI rate limit or quota reached. Check your API account and try again later.'**
  String get scanRateError;

  /// No description provided for @scanNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Extraction failed or timed out. Check your connection and try again.'**
  String get scanNetworkError;

  /// No description provided for @scanOutputError.
  ///
  /// In en, this message translates to:
  /// **'No usable recipe was returned. Try a clearer document or enter the recipe manually.'**
  String get scanOutputError;

  /// No description provided for @scanFileError.
  ///
  /// In en, this message translates to:
  /// **'Choose one PDF or up to 10 JPEG/PNG images, no more than 20 MB in total.'**
  String get scanFileError;

  /// No description provided for @jsonReview.
  ///
  /// In en, this message translates to:
  /// **'Review imported content before saving. Schema.org ingredient text is preserved; fill in quantities, timings, and stage references as needed.'**
  String get jsonReview;

  /// No description provided for @stageColumn.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stageColumn;

  /// No description provided for @preparationColumn.
  ///
  /// In en, this message translates to:
  /// **'Ingredients and preparation'**
  String get preparationColumn;

  /// No description provided for @durationColumn.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationColumn;

  /// No description provided for @temperatureColumn.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureColumn;

  /// No description provided for @planBake.
  ///
  /// In en, this message translates to:
  /// **'Plan a bake'**
  String get planBake;

  /// No description provided for @noBakes.
  ///
  /// In en, this message translates to:
  /// **'No baking sessions yet. Add a recipe to plan your next bake.'**
  String get noBakes;

  /// No description provided for @chooseBakingRecipe.
  ///
  /// In en, this message translates to:
  /// **'Choose a recipe'**
  String get chooseBakingRecipe;

  /// No description provided for @noReadyRecipes.
  ///
  /// In en, this message translates to:
  /// **'No complete recipes available. Add ingredients, stages, and timings to a recipe first.'**
  String get noReadyRecipes;

  /// No description provided for @plannedStart.
  ///
  /// In en, this message translates to:
  /// **'Planned start'**
  String get plannedStart;

  /// No description provided for @plannedEnd.
  ///
  /// In en, this message translates to:
  /// **'Planned end'**
  String get plannedEnd;

  /// No description provided for @readyBetween.
  ///
  /// In en, this message translates to:
  /// **'Ready between'**
  String get readyBetween;

  /// No description provided for @sessionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sessionStatus;

  /// No description provided for @bakePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get bakePlanned;

  /// No description provided for @bakeActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get bakeActive;

  /// No description provided for @bakeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bakeCompleted;

  /// No description provided for @stepPending.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get stepPending;

  /// No description provided for @stepRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stepRunning;

  /// No description provided for @stepPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get stepPaused;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepCompleted;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingTime;

  /// No description provided for @startStep.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startStep;

  /// No description provided for @pauseStep.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseStep;

  /// No description provided for @resumeStep.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeStep;

  /// No description provided for @completeStep.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get completeStep;

  /// No description provided for @waitingDependencies.
  ///
  /// In en, this message translates to:
  /// **'Waiting for earlier stages to be marked done'**
  String get waitingDependencies;

  /// No description provided for @actionsColumn.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsColumn;

  /// No description provided for @scheduleColumn.
  ///
  /// In en, this message translates to:
  /// **'Start / end'**
  String get scheduleColumn;

  /// No description provided for @durationTemperature.
  ///
  /// In en, this message translates to:
  /// **'Duration / temperature'**
  String get durationTemperature;

  /// No description provided for @changeStart.
  ///
  /// In en, this message translates to:
  /// **'Change start time'**
  String get changeStart;

  /// No description provided for @chooseDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose duration'**
  String get chooseDuration;

  /// No description provided for @sessionSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the baking session. The previous saved state is unchanged. Please retry.'**
  String get sessionSaveError;

  /// No description provided for @sessionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load baking sessions.'**
  String get sessionLoadError;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveSchedule;

  /// No description provided for @removeBake.
  ///
  /// In en, this message translates to:
  /// **'Remove baking session'**
  String get removeBake;

  /// No description provided for @removeBakeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this baking session and its progress? The recipe will be kept.'**
  String get removeBakeConfirm;

  /// No description provided for @scheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Stages without earlier-stage references run in parallel. A chosen start time is the earliest allowed start; dependencies can move it later. Timers continue by clock time when you leave the view.'**
  String get scheduleHint;

  /// No description provided for @recipeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'This bake uses a saved recipe snapshot. Recipe edits apply to new baking sessions.'**
  String get recipeSnapshot;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed — check this step'**
  String get overdue;

  /// No description provided for @durationRangeError.
  ///
  /// In en, this message translates to:
  /// **'Choose whole minutes within the recipe’s duration range.'**
  String get durationRangeError;

  /// No description provided for @openBake.
  ///
  /// In en, this message translates to:
  /// **'Open baking session'**
  String get openBake;

  /// No description provided for @sessionStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Session start'**
  String get sessionStartLabel;

  /// No description provided for @actualStart.
  ///
  /// In en, this message translates to:
  /// **'Actual start'**
  String get actualStart;

  /// No description provided for @actualEnd.
  ///
  /// In en, this message translates to:
  /// **'Actual end'**
  String get actualEnd;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @tableView.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableView;

  /// No description provided for @timelineDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a bar to move the step. Drag its right edge to change duration within the allowed range. Double-click for an exact start time. Esc cancels a drag.'**
  String get timelineDragHint;

  /// No description provided for @timelineResizeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to change duration; click for exact minutes'**
  String get timelineResizeHint;

  /// No description provided for @timelineLocked.
  ///
  /// In en, this message translates to:
  /// **'Started steps are locked against moving or resizing.'**
  String get timelineLocked;

  /// No description provided for @timelineFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get timelineFit;

  /// No description provided for @timelineZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get timelineZoomIn;

  /// No description provided for @timelineZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get timelineZoomOut;

  /// No description provided for @timelineEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get timelineEarlier;

  /// No description provided for @timelineLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get timelineLater;

  /// No description provided for @bakingHelp.
  ///
  /// In en, this message translates to:
  /// **'About this baking schedule'**
  String get bakingHelp;

  /// No description provided for @dependencyWaiting.
  ///
  /// In en, this message translates to:
  /// **'{predecessor} is ready {duration} before {successor} starts.'**
  String dependencyWaiting(
    String predecessor,
    String successor,
    String duration,
  );

  /// No description provided for @dependencyTooEarly.
  ///
  /// In en, this message translates to:
  /// **'{predecessor} is ready {duration} before use in {successor}; the recipe’s maximum duration is exceeded by {excess}. Review this waiting time.'**
  String dependencyTooEarly(
    String predecessor,
    String successor,
    String duration,
    String excess,
  );

  /// No description provided for @dependencyConflict.
  ///
  /// In en, this message translates to:
  /// **'{successor} starts {duration} before {predecessor} is ready. Actual step times remain unchanged.'**
  String dependencyConflict(
    String predecessor,
    String successor,
    String duration,
  );

  /// No description provided for @timingWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check connected steps'**
  String get timingWarningsTitle;

  /// No description provided for @timingWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting between steps'**
  String get timingWaitingTitle;

  /// No description provided for @timelineConnectionLegend.
  ///
  /// In en, this message translates to:
  /// **'Dashed links show waiting. Amber or red links need review. Highlighted bars follow the step being changed.'**
  String get timelineConnectionLegend;

  /// No description provided for @timelineAffected.
  ///
  /// In en, this message translates to:
  /// **'Recalculated with the changed step'**
  String get timelineAffected;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make room for your next good bake.'**
  String get settingsSubtitle;

  /// No description provided for @recipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your recipes, ready for the next bake.'**
  String get recipesSubtitle;

  /// No description provided for @plannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A clear view of what is baking and what comes next.'**
  String get plannerSubtitle;

  /// No description provided for @aiSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal OpenAI API key for photo and PDF recipe imports.'**
  String get aiSettingsDescription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemAppearance.
  ///
  /// In en, this message translates to:
  /// **'Light and dark appearance follows your system settings.'**
  String get systemAppearance;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Back-o-Mat'**
  String get aboutApp;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Bread recipes, thoughtful planning, and a little more calm on baking day. Your recipes and baking progress are stored on this device.'**
  String get aboutDescription;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
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
