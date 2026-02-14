---
name: rider-ssr-config
description: Generate Rider/ReSharper Structural Search and Replace (SSR) XML configuration for DotSettings files. Use this skill when the user wants to create a structural search pattern, a search-and-replace pattern, or custom code inspection rules for Rider, ReSharper, or IntelliJ IDEA in the DotSettings XML format. Handles placeholder definitions (Expression, Type, Identifier, Argument, Statement), severity levels, and all pattern options. Outputs ready-to-paste XML — does NOT modify any project files.
---

# Rider Structural Search & Replace Configuration Generator

Generate DotSettings XML for Rider/ReSharper Structural Search and Replace patterns. Output XML to the chat — never modify project files.

## Workflow

1. Gather pattern details from the user (search pattern, optional replace pattern, placeholders, options).
2. Generate a GUID for the pattern (uppercase hex, 32 chars, no hyphens).
3. Build the XML lines following the schema in [references/schema.md](references/schema.md).
4. Present the XML in a fenced code block with guidance on where to paste it.

## Gathering Input

Ask for or infer from context:

- **Search pattern** (required): C# code with `$name$` placeholders. Example: `$args$.State = $value$;`
- **Replace pattern** (optional): if provided, generates a replace pattern. Example: `$args$.SetState($value$);`
- **Placeholders**: for each `$name$` in the patterns, determine the type and properties. See [references/schema.md](references/schema.md) for all placeholder types.
- **Options** (all optional, have defaults):
  - `Severity`: ERROR (default), WARNING, SUGGESTION, HINT, DO_NOT_SHOW
  - `Comment` / `ReplaceComment`: description shown in the inspection list
  - `SuppressionKey`: custom key for `// ReSharper disable` comments
  - `FormatAfterReplace`: default False
  - `ShortenReferences`: default False (omitted when default)
  - `MatchCatchClauseWithoutExceptionFilter`: default False
  - `LanguageName`: CSHARP (default), VBASIC, or others

## Generating the XML

Read [references/schema.md](references/schema.md) for the full XML schema, placeholder types, property details, and encoding rules.

Key rules:
- Generate a random 32-character uppercase hex GUID (no hyphens) for each pattern.
- XML-encode `<` as `&lt;`, `>` as `&gt;`, `&` as `&amp;` in SearchPattern, ReplacePattern, and placeholder property values.
- Only emit `IsReplacePattern`, `ReplacePattern`, `FormatAfterReplace`, `ShortenReferences`, and `MatchCatchClauseWithoutExceptionFilter` when a replace pattern is provided.
- Always emit `@KeyIndexDefined` as the first line.
- Emit placeholder lines grouped per placeholder, after all pattern-level lines.
- For search-only patterns (no replace), emit: `@KeyIndexDefined`, `Comment` (if provided), `LanguageName`, `SearchPattern`, `Severity`, and placeholder blocks.

## Output Format

Present the XML inside a fenced XML code block. Add a brief note:

> Paste this XML into your `.DotSettings` file (team-shared or personal) inside the root `<wpf:ResourceDictionary>` element, alongside other `PatternsAndTemplates/StructuralSearch` entries.
