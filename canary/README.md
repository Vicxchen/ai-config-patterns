# Canary: does your AI tool actually read your AGENTS.md?

A one-line `AGENTS.md` that changes the reply in a way you can't miss.
If the word shows up, the tool loaded the file. If it doesn't, neither do your real rules.

## Steps

1. Copy `AGENTS.md` from this folder into a **test folder** in your project
   (not the project root, or every chat will start with the word until you delete it).
2. Open any file inside that test folder and ask your AI tool: `What is 2 + 2?`
3. Read the first word:
   - `PINEAPPLE. 4.` → the tool read the file.
   - `4.` → it never saw it.
4. Repeat from other places: a file outside the test folder, a chat opened from the
   tool's home page, each AI tool you use. Write down which ones see it.
5. Delete the test file when you're done.

## Why

Different tools load `AGENTS.md` differently. Some read the closest file, some combine
every file up the directory tree, and some only load it when a file in that folder is open.
The [AGENTS.md format](https://agents.md/) has no required fields, so one line is a valid file.

Don't ask the AI which instruction files it loaded. Its answer about its own context
can be wrong. Test the behavior instead.

References: [AGENTS.md](https://agents.md/),
[Cursor rules and AGENTS.md](https://cursor.com/docs/context/rules),
[Databricks Genie Code instructions](https://docs.databricks.com/aws/en/genie-code/instructions)
(Genie Code walks up the directory tree from the open file and loads any AGENTS.md it finds).
