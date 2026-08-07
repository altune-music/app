# GEARS Spec Format

Specs use [GEARS](https://sublang.ai/ref/gears-ai-ready-spec-syntax) syntax.

## Format

```
### Behavior title

Where <static preconditions>
While <stateful preconditions>
When <trigger>
The <subject> shall <behavior>
And shall <additional behavior>
```

## Keywords

| Keyword | Purpose |
|---------|----------|
| `Where` | Static preconditions (device type, screen state) |
| `While` | Dynamic preconditions (playback state, UI visibility) |
| `When` | Trigger event (user action, system event) |
| `shall` | Required behavior |

## Example

```
### Playing a song

Where the app is on the library screen
While a song is selected
When the user taps play
The player shall start playback of the selected song
And the mini player shall show the now-playing state
```

## Guidelines

- Specs document **what the user sees**, not implementation details.
- No code, class names, or technical specs in the spec itself.
- State present behavior, not absent bugs — never write "shall not crash."
- Use [CONTEXT.md](context.md) for canonical domain terminology.
