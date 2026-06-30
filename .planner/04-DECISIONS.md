<!--
  04-DECISIONS.md — the living decision register.
  OWNER: the PLANNER. Every decision is a revisable entry. Golden rule: the
  planner proposes, the OWNER promotes — a decision only reaches ACCEPTED with an
  explicit "yes" from the owner, and stays revisable afterward. Never fabricate a
  commercial value (price, rate, date, copy): if it is not settled, it is an OPEN
  QUESTION, not a decision.
-->

# 04 — Decision register (living)

> **Nothing is set in stone.** Each decision is a revisable entry. Golden rule:
> **the planner proposes, the owner promotes** — a decision only reaches
> `ACCEPTED` with an explicit "yes" from the owner, and stays revisable after.
>
> **Format of each entry:**
> - **Status:** `PROPOSED` | `ACCEPTED` | `REVISIT` | `SUPERSEDED`
> - **Confidence:** high / medium / low
> - **Origin:** who proposed it — and is it confirmed by the owner?
> - **What:** the decision, in one or two plain sentences.
> - **Why:** the reasoning (so a wrong premise shows itself).
> - **Review-trigger:** what would make us reconsider.
>
> Never fabricate a commercial value (price, rate, date, copy): if it is not
> settled, it is an **open question**, not a decision. Park open questions at the
> bottom of this file until they are promoted.

---

## Decisions

### DEC-001 · \<short decision title\>
- **Status:** ACCEPTED · **Confidence:** high · **Origin:** owner (initial brief, explicit)
- **What:** \<the decision, in one or two plain sentences\>.
- **Why:** \<the reasoning that makes this the right call\>.
- **Review-trigger:** \<the concrete signal that would make us revisit this\>.

> The entry above is a **worked example** showing the exact format. Replace it
> with your first real decision. Below are two more shapes you will need.

### DEC-002 · \<a decision still being proposed\>
- **Status:** PROPOSED · **Confidence:** medium · **Origin:** planner (awaiting the owner's "yes")
- **What:** \<the proposed decision\>.
- **Why:** \<the reasoning + the assumptions it bets on, in the open\>.
- **Review-trigger:** —

### DEC-003 · \<a decision that replaced an earlier one\>
- **Status:** ACCEPTED · **Confidence:** high · **Origin:** owner (course-correction)
- **What:** \<the new decision\>.
- **Supersedes:** DEC-00N (which was carved in too early — see the lesson below).
- **Why:** \<why the earlier call was wrong and this one is right\>.

---

## Open questions (NOT decisions)

> Things that are not settled. Keep them here, framed as questions, until the
> owner promotes one to a decision above. **Never** invent a value just to close a
> question — an honest open question beats a fabricated decision.

- **\<commercial value X\> (price / rate / date / copy)** — unsettled. Do **not**
  write a number anywhere downstream (copy, code, docs) until the owner sets it.
  Verify the real value before publishing any claim that depends on it.
- **\<validation environment\>** — local first, a separate test environment, or
  staging? To be discussed with the owner before P3.
