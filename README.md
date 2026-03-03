# StoryFix - CLI tool to fix that story

A simple CLI tool that applies pre-configured LLM "fixes" to text via
OpenRouter. Change your protagonist's gender pronouns everywhere in the
text. Rewrite the whole story in present tense. Change from first person POV to
third person limited omniscient. Translate it to Spanish. Replace the goblins
with orcs. The possibilities, while not endless, seem pretty open.


> [!CAUTION]
> **This is my first agentic coded app. This is my "hello world" for
> agentic coding.** Not only will your mileage vary, but your car might burst
> into flames. Remember: The chance of your PC getting suborned into a Skynet
> botnet is slim _but never zero._

TODO: A non-CLI version soon, for all you webheads and GUI nerds. This is just
the CLI version.

# Storyfix

Here's a story snippet. It's all right. It's short for this demo, but could be
hundreds to thousands of tokens long.

```bash
$ cat tyrian.md
Tyrian walked to his front door and pulled it open with a heavy sigh. He knew he
only had three days left to come up with the rent, and his landlord was not a
patient man.
```

What if Tyrian was nonbinary and favored they/them pronouns? I've already added fix for gender:

```bash
$ storyfix list
gender - Set character's gender

$ storyfix show gender
Name: gender
Description: Set character's gender
Body:
Please change {{1}}'s pronouns to {{2}}.

$ storyfix -i tyrian.md gender Tyrian they/them
Tyrian walked to their front door and pulled it open with a heavy sigh. They knew they
only had three days left to come up with the rent, and their landlord was not a
patient man.
```

The gender fix catches 2 arguments: the character and the gender. We don't have
to do Tyrian. Let's make the landlord female. Because it's an LLM, it doesn't
have to just update pronouns. we can say she/her, female, feminine, etc:

```bash
$ storyfix -i tyrian.md gender landlord female
Tyrian walked to his front door and pulled it open with a heavy sigh. He knew he
only had three days left to come up with the rent, and his landlady was not a
patient woman.
```

And because it's an LLM, you can squeeze extra information in the substitution:

```bash
$ storyfix -i tyrian.md gender landlord "female (but keep title 'landlord', she hates being a 'landlady')"
Tyrian walked to his front door and pulled it open with a heavy sigh. He knew he
only had three days left to come up with the rent, and his landlord was not a
patient woman.
```

Hmm. I don't like past tense though. Let's change that. We need to write a
fix. Give it a name, a short description, and then an edit request.

```bash
$ storyfix add tense "Narrator verb tense" "Please change the narrator's verb tense to {{1}}."
storyfix: success: Fix 'tense' created.

$ storyfix -i tyrian.md tense "past progressive"
Tyrian was walking to his front door and was pulling it open with a heavy
sigh. He was knowing he only had three days left to come up with the rent, and
his landlord was not a patient man.
```

Okay that was silly. Let's just do present tense.

```bash
$ storyfix -i tyrian.md tense "present"
Tyrian walks to his front door and pulls it open with a heavy sigh. He knows he
only has three days left to come up with the rent, and his landlord is not a
patient man.
```

Decent.

How far can this go? That's up to you. How crazy do you want to get in your
prompt?

I work on a lot of story cards from other authors that write terribly and/or
don't speak fluent English. Let's say we just got this:

> Tyrian was walking to front door and open it with a heavy sigh. He know he got three days for coming up with rent, and he dueño not patient.

By default, storyfix tries to stay verbatim as possible. Let's add a rule to
rewrite more freely in an open novelization style.

```bash
$ storyfix add novel-big "Novelization rewrite (big rewrites)" "Please rewrite this story as faithfully as possible to the spirit of the original, but write in clean, modern English novelization format. This is not a verbatim rewrite. YOU MAY ADD VERBIAGE. Keep a clean, emotive novelization flow. Don't be overly florid, awkward, or cerebral. Ground characters in the reality of the story."
storyfix: success: Fix 'novel-big' created.

$ storyfix -i tyrian-esl.md novel-big
Tyrian approached the front door, his footsteps heavy with exhaustion. He paused, hand on the doorknob, and exhaled a weary sigh that seemed to carry the weight of his entire world. The rent was due in three days, and his landlord was not known for mercy or understanding. Each step, each breath was a reminder of the precarious edge he balanced on—survival was never guaranteed, and neither was a roof over his head.
```

I wouldn't trust it for translation, but eh, why not. Let's make a generic "fix"
rule that lets us say whatever we want.

```bash
$ storyfix add fix "Arbitrary fix (must specify)" "{{1}}"
storyfix: success: Fix 'fix' created.

$ storyfix -i tyrian.md fix "Please translate to hilariously flamboyant Puerto Rican Spanish. BORICA DE CORAZON WEPAAAAA~~"
BORICA DE CORAZON WEPAAAAA~~

¡Ay, Dios mío, mi Tyrian! Camineó hasta su puertota con un suspiro más dramático
que una telenovela, ¡coño! Él sabía que solo le quedaban tres días pa' juntar
los cuartos del alquiler, y su casero era más bravo que un tsunami en Santurce,
¡WEPA! 🌴🔥💃

# I saved the above to tyrian-boricua.md, let's translate it back
$ cat tyrian-boricua.md | storyfix fix "Please translate this to English. Stay as literal as possible, don't port idioms."
OH MY HEART BORICA WEPAAAAA~~

Oh my God, my Tyrian! He walked to his big door with a sigh more dramatic than a soap opera, damn! He knew he only had three days to gather the rent money, and his landlord was more fierce than a tsunami in Santurce, WEPA! 🌴🔥💃
```

And just for fun:

```bash
$ storyfix add l33t "leetspeak, god help me" 'lol rewrite it in l33tsp34|<. L1k3 t0t@Lly g0 n|_|tz!!!!1!one lulz'
storyfix: success: Fix 'l33t' created.
21:18:03 dbrady@vapor:~  ruby-3.4.8
$ storyfix -i tyrian.md l33t
7yr!@n w@lk3d 2 h1z fr0n7 d00r @nd pu11d !7 0p3n w!7h @ h3@vy s!gh. h3 kn3w h3
0n1y h@d 7hr33 d@yz l3f7 2 c0m3 up w!7h 7h3 r3n7, @nd h1z l@ndl0rd w@z n07 @
p@7!3n7 m@n.
```

It's a litle too over-encoded, but you get the idea.

# Known Issues

This was a scratch vibecode project, I'll work on the system prompt. For now, be
tolerant, your mileage very likely will vary.

If in doubt, it's your fault for trusting me to write software. :-P

### Wrapping

The LLM is really inconsiderate of whitespace. That's pretty racist, but
okay. If I can fix this I will. But for now be ready for word-wrapping to be
added or removed. Half the examples in here came back unwrapped. I had to
manually wrap them to fit in this README.

### Show AND Tell

Sometimes the LLM prepends or appends commentary, telling you what it's showing
you.

For now, don't just blindly run this tool. Check the output!

```bash
$ storyfix -i tyrian.md tense "past progressive"
Here's the text with the narrator's verb tense changed to past progressive:

Tyrian was walking to his front door and was pulling it open with a heavy
sigh. He was knowing he only had three days left to come up with the rent, and
his landlord was not a patient man.
```


### Error/Clarification

If there's a confusion, the LLM will add it as commentary. I'll clean that up
when I revisit the prompt.

```bash
$ storyfix -i tyrian.md tense "past"
Tyrian walked to his front door and pulled it open with a heavy sigh. He knew he
only had three days left to come up with the rent, and his landlord was not a
patient man.

(Note: The text was already entirely in past tense, so no changes were necessary.)
```

### As-Yet-Untested

When the AI can't understand your text, instead of doing its best it may crap
out. Oh well!


> [!NOTE]
> The README to this point was written by me. From here on out, this is written
> entirely with agentic coding. The rest of the README, all of the code, the
> installation, the defaults intialization, etc.
>
> If this app is terrible, it's not because I'm bad at programming, it's because
> I'm bad at AI.

## Installation

```bash
gem install storyfix
```
Or clone the repository and run:
```bash
bundle install
chmod +x bin/storyfix
```

## Quick Start

1. Set your OpenRouter API key:
   ```bash
   storyfix set-config api-key "sk-or-v1-..."
   ```
   Or use the `OPENROUTER_API_KEY` environment variable.

2. Create a fix (you can use `{{1}}`, `{{2}}` to interpolate arguments):
   ```bash
   storyfix add pov "Change point of view" "Rewrite the following text from the point of view of {{1}}."
   ```

3. Run the fix on a file and output to stdout:
   ```bash
   storyfix pov "a grumpy cat" -i input.txt
   ```

4. Overwrite the file in place:
   ```bash
   storyfix pov "a grumpy cat" -i input.txt -I
   ```

## Warning

**Cost Warning:** This tool makes calls to the OpenRouter API. Depending on the model you configure, this can incur significant costs. Monitor your API usage to avoid unexpected charges.

## Configuration

Settings are stored in `~/.config/storyfix/storyfix.db`.

```bash
storyfix set-config default-model anthropic/claude-3-haiku
storyfix get-config default-model
storyfix list-configs
```

### CSAM and Refusals
If the user request violates safety guidelines, the LLM may refuse the request cleanly. Using `--in-place` (`-I`) carries the risk of overwriting your input file with a refusal message or an empty response. Always keep a backup or use version control.
