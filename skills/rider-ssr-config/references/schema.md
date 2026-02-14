# DotSettings Structural Search XML Schema

## Key Path Structure

Every line is a `<s:Boolean>` or `<s:String>` element. The `x:Key` attribute encodes the setting path:

```
/Default/PatternsAndTemplates/StructuralSearch/Pattern/={GUID}/...
```

`{GUID}` is a 32-character uppercase hexadecimal string (no hyphens). Generate one randomly per pattern.

## Pattern-Level Properties

Emit in this order. The `P` prefix below stands for the full key path `/Default/PatternsAndTemplates/StructuralSearch/Pattern/={GUID}`.

| # | Key suffix | XML type | Required | Notes |
|---|-----------|----------|----------|-------|
| 1 | `/@KeyIndexDefined` | Boolean | Always | Always `True` |
| 2 | `/Comment/@EntryValue` | String | Optional | Description shown in inspection list |
| 3 | `/FormatAfterReplace/@EntryValue` | Boolean | Replace only | Typically `False` |
| 4 | `/IsReplacePattern/@EntryValue` | Boolean | Replace only | `True` when replace pattern exists |
| 5 | `/LanguageName/@EntryValue` | String | Always | `CSHARP`, `VBASIC`, etc. |
| 6 | `/MatchCatchClauseWithoutExceptionFilter/@EntryValue` | Boolean | Replace only | Typically `False` |
| 7 | `/ReplaceComment/@EntryValue` | String | Optional | Description for the replacement |
| 8 | `/ReplacePattern/@EntryValue` | String | Replace only | The replacement code |
| 9 | `/SearchPattern/@EntryValue` | String | Always | The search code |
| 10 | `/Severity/@EntryValue` | String | Always | `ERROR`, `WARNING`, `SUGGESTION`, `HINT`, `DO_NOT_SHOW` |
| 11 | `/ShortenReferences/@EntryValue` | Boolean | Optional | Typically `False` for replace patterns |
| 12 | `/SuppressionKey/@EntryValue` | String | Optional | Custom key for `// ReSharper disable` |

After all pattern-level lines, emit placeholder blocks.

## Placeholder Blocks

Each placeholder `$name$` used in the search/replace patterns needs a block under:

```
P/CustomPatternPlaceholder/={name}/...
```

### Placeholder block structure (per placeholder)

| # | Key suffix | XML type | Notes |
|---|-----------|----------|-------|
| 1 | `/@KeyIndexDefined` | Boolean | Always `True` |
| 2 | `/Properties/=.../@EntryIndexedValue` | String | Type-specific properties (see below) |
| 3 | `/Type/@EntryValue` | String | Placeholder type identifier |

### Placeholder Types

#### ExpressionPlaceholder

Matches a C# expression. Type value: `ExpressionPlaceholder`

Properties:
- `ExactType` (String): `"True"` or `"False"` — whether the type must match exactly (not a derived type). Default: `"False"`.
- `ExpressionType` (String): Fully qualified type name to constrain the expression. Empty string for any expression.

Example — typed expression:
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=args/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=args/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=args/Properties/=ExpressionType/@EntryIndexedValue">Skye.BusinessCanvas.Migrations.Definition.DefinitionMigrationArgs</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=args/Type/@EntryValue">ExpressionPlaceholder</s:String>
```

Example — any expression (no type constraint):
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=value/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=value/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=value/Properties/=ExpressionType/@EntryIndexedValue"></s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=value/Type/@EntryValue">ExpressionPlaceholder</s:String>
```

ExpressionPlaceholder can also carry argument-count properties when used in an argument-like context:
- `Minimal` (String): Minimum number of arguments. `"-1"` = no limit.
- `Maximal` (String): Maximum number of arguments. `"-1"` = no limit.

#### TypePlaceholder

Matches a C# type name. Type value: `TypePlaceholder`

Properties:
- `ExactType` (String): `"True"` or `"False"`. Default: `"False"`.
- `Type` (String): Fully qualified type to constrain. Empty string for any type.

Example:
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=type/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=type/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=type/Properties/=Type/@EntryIndexedValue"></s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=type/Type/@EntryValue">TypePlaceholder</s:String>
```

#### IdentifierPlaceholder

Matches an identifier (variable, method, property name). Type value: `IdentifierPlaceholder`

Properties:
- `ExactType` (String): `"True"` or `"False"`. Default: `"False"`.
- `RegEx` (String): Regular expression to constrain the identifier name. Empty string for any identifier.
- `CaseSensitive` (String): `"True"` or `"False"` for the regex. Default: `"True"`.

Example:
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=spans/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=spans/Properties/=CaseSensitive/@EntryIndexedValue">True</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=spans/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=spans/Properties/=RegEx/@EntryIndexedValue"></s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=spans/Type/@EntryValue">IdentifierPlaceholder</s:String>
```

#### ArgumentPlaceholder

Matches one or more arguments in a method call. Type value: `ArgumentPlaceholder`

Properties:
- `Minimal` (String): Minimum number of arguments. `"-1"` = no limit.
- `Maximal` (String): Maximum number of arguments. `"-1"` = no limit.

Example:
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=Param/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=Param/Properties/=Maximal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=Param/Properties/=Minimal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=Param/Type/@EntryValue">ArgumentPlaceholder</s:String>
```

#### StatementPlaceholder

Matches one or more statements. Type value: `StatementPlaceholder`

Properties:
- `Minimal` (String): Minimum number of statements. `"-1"` = no limit.
- `Maximal` (String): Maximum number of statements. `"-1"` = no limit.

Example:
```xml
<s:Boolean x:Key="P/CustomPatternPlaceholder/=stmts/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="P/CustomPatternPlaceholder/=stmts/Properties/=Maximal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=stmts/Properties/=Minimal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="P/CustomPatternPlaceholder/=stmts/Type/@EntryValue">StatementPlaceholder</s:String>
```

## XML Encoding Rules

In `SearchPattern`, `ReplacePattern`, and all property values:
- `<` must be encoded as `&lt;`
- `>` must be encoded as `&gt;`
- `&` must be encoded as `&amp;`
- `"` inside attribute values must be encoded as `&quot;` (though the outer quotes use `"`)
- `=>` (lambda arrow) becomes `=&gt;`

Example: `A<$T$>.Ignored` becomes `A&lt;$T$&gt;.Ignored` in the XML value.

## Complete Examples

### Example 1: Search-and-Replace Pattern (Expression placeholders)

**Input:**
- Search: `$args$.State = $value$;`
- Replace: `$args$.SetState($value$);`
- `$args$`: Expression of type `Skye.BusinessCanvas.Migrations.Definition.DefinitionMigrationArgs`
- `$value$`: Expression (any)
- Severity: ERROR

**Output:**
```xml
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/@KeyIndexDefined">True</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=args/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=args/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=args/Properties/=ExpressionType/@EntryIndexedValue">Skye.BusinessCanvas.Migrations.Definition.DefinitionMigrationArgs</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=args/Type/@EntryValue">ExpressionPlaceholder</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=value/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=value/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=value/Properties/=ExpressionType/@EntryIndexedValue"></s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/CustomPatternPlaceholder/=value/Type/@EntryValue">ExpressionPlaceholder</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/FormatAfterReplace/@EntryValue">False</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/IsReplacePattern/@EntryValue">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/LanguageName/@EntryValue">CSHARP</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/MatchCatchClauseWithoutExceptionFilter/@EntryValue">False</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/ReplacePattern/@EntryValue">$args$.SetState($value$);</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/SearchPattern/@EntryValue">$args$.State = $value$;</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/Severity/@EntryValue">ERROR</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=8BBF5CB8C913D24BBE1CF5934D5ABBAB/ShortenReferences/@EntryValue">False</s:Boolean>
```

### Example 2: Search-and-Replace with Type Placeholder (requires XML encoding)

**Input:**
- Search: `($type$)$args$.State`
- Replace: `$args$.GetState<$type$>()`
- `$args$`: Expression of type `Skye.BusinessCanvas.Migrations.Definition.DefinitionMigrationArgs`
- `$type$`: Type (any)
- Severity: ERROR

**Output:**
```xml
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/@KeyIndexDefined">True</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=args/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=args/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=args/Properties/=ExpressionType/@EntryIndexedValue">Skye.BusinessCanvas.Migrations.Definition.DefinitionMigrationArgs</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=args/Type/@EntryValue">ExpressionPlaceholder</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=type/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=type/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=type/Properties/=Type/@EntryIndexedValue"></s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/CustomPatternPlaceholder/=type/Type/@EntryValue">TypePlaceholder</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/FormatAfterReplace/@EntryValue">False</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/IsReplacePattern/@EntryValue">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/LanguageName/@EntryValue">CSHARP</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/MatchCatchClauseWithoutExceptionFilter/@EntryValue">False</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/ReplacePattern/@EntryValue">$args$.GetState&lt;$type$&gt;()</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/SearchPattern/@EntryValue">($type$)$args$.State</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/Severity/@EntryValue">ERROR</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=A8B545B1087CDA4A87F0C5D55FABDFA4/ShortenReferences/@EntryValue">False</s:Boolean>
```

### Example 3: Search-Only Pattern (no replace, with Identifier placeholder)

**Input:**
- Search: `RaisePropertyChanged()`
- Comment: `Use RaisePropertyChanged(nameof(...)) instead of RaisePropertyChanged()`
- Severity: ERROR
- No replace pattern

**Output:**
```xml
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=26BC824A922BA74D98FD19947DB12082/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=26BC824A922BA74D98FD19947DB12082/Comment/@EntryValue">Use RaisePropertyChanged(nameof(...)) instead of RaisePropertyChanged()</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=26BC824A922BA74D98FD19947DB12082/LanguageName/@EntryValue">CSHARP</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=26BC824A922BA74D98FD19947DB12082/SearchPattern/@EntryValue">RaisePropertyChanged()</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=26BC824A922BA74D98FD19947DB12082/Severity/@EntryValue">ERROR</s:String>
```

### Example 4: Replace with Identifier placeholder and SuppressionKey

**Input:**
- Search: `RaisePropertyChanged(() => $arg$)`
- Replace: `RaisePropertyChanged(nameof($arg$))`
- `$arg$`: Identifier (any, case-sensitive)
- Comment: `Replace RaisePropertyChanged(() => $arg$) with RaisePropertyChanged(nameof($arg$))`
- SuppressionKey: `RaisePropertyChangedNameOf`
- Severity: ERROR

**Output:**
```xml
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/Comment/@EntryValue">Replace RaisePropertyChanged(() =&gt; $arg$) with RaisePropertyChanged(nameof($arg$))</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/FormatAfterReplace/@EntryValue">False</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/IsReplacePattern/@EntryValue">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/LanguageName/@EntryValue">CSHARP</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/MatchCatchClauseWithoutExceptionFilter/@EntryValue">False</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/ReplaceComment/@EntryValue">Replace RaisePropertyChanged(() =&gt; $arg$) with RaisePropertyChanged(nameof($arg$))</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/ReplacePattern/@EntryValue">RaisePropertyChanged(nameof($arg$))</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/SearchPattern/@EntryValue">RaisePropertyChanged(() =&gt; $arg$)</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/Severity/@EntryValue">ERROR</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/ShortenReferences/@EntryValue">False</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/SuppressionKey/@EntryValue">RaisePropertyChangedNameOf</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/CustomPatternPlaceholder/=arg/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/CustomPatternPlaceholder/=arg/Properties/=CaseSensitive/@EntryIndexedValue">True</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/CustomPatternPlaceholder/=arg/Properties/=ExactType/@EntryIndexedValue">False</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/CustomPatternPlaceholder/=arg/Properties/=RegEx/@EntryIndexedValue"></s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=CE18094233715F46910908F39F726663/CustomPatternPlaceholder/=arg/Type/@EntryValue">IdentifierPlaceholder</s:String>
```

### Example 5: Search-and-Replace with ArgumentPlaceholder

**Input:**
- Search: `Assert.DoesNotThrow($Param$);`
- Replace: `Assert.That($Param$, Throws.Nothing);`
- `$Param$`: Argument (min: -1, max: -1)
- Comment: `Prefer Assert.That to Assert.DoesNotThrow`
- Severity: ERROR

**Output:**
```xml
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/Comment/@EntryValue">Prefer Assert.That to Assert.DoesNotThrow</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/FormatAfterReplace/@EntryValue">False</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/IsReplacePattern/@EntryValue">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/LanguageName/@EntryValue">CSHARP</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/MatchCatchClauseWithoutExceptionFilter/@EntryValue">False</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/ReplacePattern/@EntryValue">Assert.That($Param$, Throws.Nothing);</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/SearchPattern/@EntryValue">Assert.DoesNotThrow($Param$);</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/Severity/@EntryValue">ERROR</s:String>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/ShortenReferences/@EntryValue">False</s:Boolean>
<s:Boolean x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/CustomPatternPlaceholder/=Param/@KeyIndexDefined">True</s:Boolean>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/CustomPatternPlaceholder/=Param/Properties/=Maximal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/CustomPatternPlaceholder/=Param/Properties/=Minimal/@EntryIndexedValue">-1</s:String>
<s:String x:Key="/Default/PatternsAndTemplates/StructuralSearch/Pattern/=E0CA487544E7054C910FDDDD76B32DC7/CustomPatternPlaceholder/=Param/Type/@EntryValue">ArgumentPlaceholder</s:String>
```
