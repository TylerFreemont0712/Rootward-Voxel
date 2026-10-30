# The story window — 2026-10-28

The portrait conversation (`WorkshopScene`) was a full-width card whose height followed the text, whose side margins followed which portraits were showing, and whose choices floated above it in a separate box. Between pages the card visibly resized, and a reply page looked like a second and third window.

It is now one window:

* **One size and place for every page.** 69% of the screen wide and 22.5% high (clamped, so never smaller than 188 px or larger than 300 px high), centred, resting about 3% above the bottom. That is the size of the empty rectangle in the review screenshot. Its layout is computed from the screen alone, so a short line, a long narration and a ticket page are all drawn identically, and so are all scenes: loft waking, the slate, the ticket, the lit lantern, the round and Hotaru's chatter. The words sit in a clipped area and cannot push the card larger; the type size follows the card's height so a long page still fits at 1280×720.
* **Choices are inside it.** Left: speaker, words, Story log and the page count. Right: the reply buttons, or Continue (or the scene's closing label) when there is nothing to choose. The close button sits in the card's top-right corner. The same column holds both, so nothing moves when choices appear.
* **Portraits** stand behind the card's top corners, smaller than before, and never change the card.
* The first frame is laid out before the fade-in begins, so the card does not appear at a default size and snap to place.

The old behaviour is gone, not hidden behind an option, and no other journey uses this class (`VillageConversation` is separate and unchanged). A test walks every page of every story scene, taking the first reply wherever there is a choice, and requires one card position and size throughout, the words inside the card, and the choice buttons inside the card and to the right of the words.

Captures at the three sizes in `evidence/sparks-workshop/story-window/`: [1920×1080 narration](../../evidence/sparks-workshop/story-window/1920/s1-narration.png), [Hotaru](../../evidence/sparks-workshop/story-window/1920/s2-hotaru.png), [choices](../../evidence/sparks-workshop/story-window/1920/s3-choices.png) and [the traveller's chosen line](../../evidence/sparks-workshop/story-window/1920/s4-player.png), with the same four at [1600×1000](../../evidence/sparks-workshop/story-window/1600/s3-choices.png) and [1280×720](../../evidence/sparks-workshop/story-window/1280/s3-choices.png).
