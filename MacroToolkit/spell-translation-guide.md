# Macro Toolkit Spell Translation

This feature helps you work with spell names that change between WoW client locales.

## What It Does

- Scans your current character spellbook
- Scans your saved macros for spell names
- Stores spell names by spell ID in `spellTranslations`
- Converts the selected macro into the current client locale (i.e. "Shadow Bolt" in enUS becomes "暗影箭" in zhTW)
- Lets you preview the converted result before overwriting the macro
- Shows the saved translation data in the side panel

## Where To Find It

Open Macro Toolkit via `/mac`, Spell Translation panel appears as a separate window next to the main Macro Toolkit frame.

## Buttons

### Save spells

Use this first in your original locale that your macros were created in.

It scans:

- macros saved
- your current character spellbook
- existing `spellTranslations` data's and updates it with any missing spell names it finds in current locale. (i.e. you saved zhTW warlock, and login as enUS priest, it will add any missing spell names for warlock in enUS)

Then it saves spell names into the translation database.

### Convert

Use this after selecting a macro in Macro Toolkit.

It reads the selected macro body, looks for supported spell references, and writes the localized result into the top preview box in the Spell Translation panel. This let's you preview the converted macro text to ensure it looks correct before overwriting the macro.

### Overwrite

This takes the converted text from the top preview box and replaces the selected macro body with it.

Use this only after checking the preview.

### Saved translations

This is the lower text area.

It shows the currently saved `spellTranslations` data only.

Each line is shown as:

```text
spellID: locale=name, locale=name
```

Example:

```text
686: enUS=Shadow Bolt, zhTW=暗影箭
```

## Notes

- The scan only knows what exists in your saved macro data and the current character spellbook.
- If a spell is missing from saved translations, convert may leave that spell name unchanged.
- The feature is intended for spell-name translation. It does not rewrite unrelated macro text.
