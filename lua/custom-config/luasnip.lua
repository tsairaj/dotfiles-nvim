local ls = require("luasnip")

-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.expand_conditions")

--[[ csharp snippets ]]

-- summay
ls.add_snippets("cs", {
  s("/// summary", fmt(
    [[
///<summary>
/// {}
///</summary>
    ]], { i(1) }
  ))
})

--[[ lua snippets ]]

ls.add_snippets("lua", {
  s("hello", {
    t('print("hello World")')
  })
})

--[[ knowledge management snippets ]]

ls.add_snippets("markdown", {
  s("troubleshooting", fmt(
    [[
---
type: troubleshooting
tags:
  - {}
---

# {}

## Stack Trace

```
{}
```

## Symptoms

## Fix

## Further Read
    ]], {
      i(1, "<tag>"),
      i(3, "<title (error message)>"),
      i(2, "<stack trace>"),
    }
  ))
})

ls.add_snippets("markdown", {
  s("recipe", fmt(
    [[
---
type: recipe
tags:
  - {}
---

# {}

## Definition
{}

## Why it Matters
{}

## How it works
{}

## Example
<minimal working example>

## Further Read
    ]], {
      i(1, "<tag>"),
      i(2, "<title>"),
      i(3, "<1–3 sentences, jargon-free if possible>"),
      i(4, "<the problem it solves / motivation>"),
      i(5, "<mental model, invariants, key mechanism>")
    }
  ))
})

ls.add_snippets("markdown", {
  s("concept", fmt(
    [[
---
type: concept
tags:
  - {}
---

# {}

## Definition
{}

## Why it Matters
{}

## How it works
{}

## Example
<minimal working example>

## Anti-patterns

## Further Read
    ]], {
      i(1, "<tag>"),
      i(2, "<title>"),
      i(3, "<1–3 sentences, jargon-free if possible>"),
      i(4, "<the problem it solves / motivation>"),
      i(5, "<mental model, invariants, key mechanism>")
    }
  ))
})

ls.add_snippets("markdown", {
  s("runbook", fmt(
    [[
---
type: runbook
tags:
  - {}
---

# {}

## Goal

## Steps

## Verification

## Further Read
    ]], {
      i(1, "<tag>"),
      i(2, "<title>"),
    }
  ))
})
