---
name: write-course
description: Write, test and improve a course (sidelab lab) of this repository. Use when asked to create a course, add or change its steps, or check that a course still runs.
---

# Writing a course

1. Read `docs/writing-courses.md`, and follow it: course shape, lab environment, variables, steps, checks, diagrams and workflow.
2. Read `AGENTS.md` for the writing style.
3. Look at an existing course in `labs/` and the fragments in `labs/shared/` before writing anything, and reuse them.
4. Research the topic online, in the official documentation, and run every command in the lab image before writing a step.
5. A course is done when `course lint` and `course verify` are green.
   A web UI is driven by `automation.yaml`, replayed against the real application before the first run, and each change made in it is a block marked `interactive action= capture=` that waits for its effect, so the run checks it.
   A course with a required secret needs its value on the launcher first: the owner sets it through the launcher's API, as sidelab's `docs/courses.md` shows, never through the agent.
6. Add every new lesson to the "Lessons learned" section of `docs/writing-courses.md`, and every new convention to its other sections.
