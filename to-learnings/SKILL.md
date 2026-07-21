---
name: to-learnings
description: Turn a grilling session into a teaching curriculum — what must be held, in what order — sliced into one brief per lesson for /teach.
disable-model-invocation: true
argument-hint: "[what was grilled, or a path to the grilling notes]"
---

# To Learnings

A grilling settled what matters. This turns that into a **curriculum** and one
**brief** per lesson, so `/teach` can be invoked one lesson at a time without
re-deciding anything. Run it in the teaching workspace: it produces the plan,
`/teach` writes the lessons.

## The two units

A **brief** is a spec: what one lesson must teach and what it must leave the
learner able to do. It carries outcomes and coverage.

The **curriculum** is the plan: why the lessons are shaped this way, the ordering,
the standing rules, and every anchor — file paths, commits, ADRs, prior art.

Anchors live in the curriculum, once. A brief points at it. `/teach` re-verifies
anchors when it writes, so a second copy only creates a second thing to drift.

## Process

### 1. Gather what the grilling settled

If the grilling wrote notes — a decisions file, ADRs, a glossary — read them in
full. Read the workspace `MISSION.md`: every lesson is justified against it, and
one that serves no success criterion is cut in step 3.

**Done when:** every decision is in context and the mission's success criteria are
written down where you can check lessons against them one by one.

### 2. Find the spine

The **spine** is what one lesson is about. Choose it from the mission's success
criteria, not from how the material is filed.

Material is usually filed by place — modules, chapters, files. Success criteria
are usually about judgement: explain why this was chosen, spot when it breaks,
decide what carries elsewhere. When those disagree, follow the criteria. A tour
organised by place can be narrated completely and still satisfy none of them.

**Done when:** you can state what a single lesson covers in a sentence that names
no file, module or chapter.

### 3. Select by what must be **held**

Some things must be *held* — carried in memory, because nothing will prompt you at
the moment you need them. Others can be *looked up* when the question arises.
Lessons are expensive; spend them on what must be held.

Two questions, and both must be yes:

1. **Does breaking it fail somewhere else?** A different request, a later run, a
   different file. If the mistake announces itself where it is made, the material
   prompts you and you do not need to hold it.
2. **Is it defended in more than one place?** If one function is the only guard,
   reading that function teaches it. Multi-site defence is what makes something
   architectural — and fragile, since any one site can drift.

Important-but-not-held is the case that catches people. Something can be a genuinely
good decision and still fail question 1 — break it and a wrong value appears on
screen immediately, right where you changed it. Nothing to hold. It becomes
reference or a later coverage pass.

Sort what you drop rather than discarding it: coverage material becomes a second
pass — usually reference pages, occasionally one lesson where the material is both
large and central.

**Done when:** every candidate is either selected or dropped **with its reason
recorded**, and each selection is tagged for transferability if the mission cares
where the knowledge carries.

### 4. Order, and record why

Order by dependency. Some lessons only land as a **contrast** and need their
counterpart taught first; some are meaningless until an earlier one supplies the
vocabulary.

Record the *reason* beside each blocker. "Blocked by 02" decays into a number
nobody can re-derive; "blocked by 02 because this only lands as a contrast to it"
survives.

Name the tension you are trading against, if there is one — commonly, the most
transferable lessons are also the hardest, so front-loading them raises the odds
of stalling before anything lands.

**Done when:** every blocker carries its reason, and any ordering trade-off is
written down as a trade rather than presented as obvious.

### 5. Design the exercise, from real history

Decide what each lesson asks the learner to *do*. Prefer exercises drawn from the
subject's **own history** — the commit that closed the hole, the revision that
withdrew a fix, the decision that was reversed.

Real history beats invented examples twice: an invented case tests whether the
learner followed your explanation, a real one tests whether they would have caught
what a practitioner actually missed — and it survives drift, since an exercise
keyed to a commit outlives one keyed to a line number.

Recognising something is easier than producing it cold. Where a lesson's idea is
invisible or abstract, add a produce-it-from-memory prompt — a real cost, so spend
it on the few lessons that need it.

**Done when:** each lesson names its exercise shape, and every exercise sourced
from history cites material you have verified exists.

### 6. Quiz the user

Present the proposed curriculum as a numbered list. Per lesson: **title**, **the
one thing it teaches**, **blocked by** (with reason), **exercise shape**.

Then ask:

- Is the spine right — are lessons about the right kind of thing?
- Does anything selected fail the held test, or anything dropped pass it?
- Is the order right, and are the blockers real?
- Is the granularity right — anything to merge or split?

Iterate until approved.

**Done when:** the user has approved the list, the order and the scope.

### 7. Write the curriculum and the briefs

Write `CURRICULUM.md` in the workspace root, and one brief per lesson under
`lessons/briefs/`, numbered in teaching order.

The curriculum carries the shape and the reasoning: why this spine, what earned a
lesson, the ordering table, the anchors, and the **standing rules** every lesson
follows. Link the briefs rather than restating them.

Keep the grilling's reasoning too — a `grilling/` directory beside the curriculum
holds the decisions and why alternatives lost. The curriculum says what to do; that
record says why, and it is what a future session reads before changing the plan.

**Done when:** one brief exists per lesson, the curriculum links them, and no
material is stated in both.

<brief-template>

# NN — Title

**Rule / subject:** the one thing this lesson exists to teach, in a sentence.

**Blocked by:** which lessons, and *why* — or "None — can start immediately".
**Transfers:** where this knowledge carries, if the mission asks.
**Curriculum:** pointer to the section holding the anchors.

## After this lesson you can

Outcomes, as things the learner can do. If the lesson does not produce these, it
failed.

## Must land

The points that have to be covered for the idea to be held. Say what makes each
one matter, not just that it exists.

## Out of scope

Deliberately excluded, so the lesson stays one sitting.

## Exercise

Which exercise shape applies, and the historical material it draws on.

## Status

`not written`

</brief-template>

## Working the briefs afterwards

Take the lowest-numbered brief whose blockers are satisfied, invoke `/teach` with
it, and clear context between lessons. The brief is the contract; the curriculum's
standing rules govern how the lesson gets written. When a lesson ships, set its
brief to `written`.
