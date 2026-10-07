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
6. Add every new lesson to the "Lessons learned" section of `docs/writing-courses.md`, and every new convention to its other sections.
