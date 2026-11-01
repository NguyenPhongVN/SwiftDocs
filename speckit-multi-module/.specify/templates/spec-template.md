# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft
**Input**: User description: "$ARGUMENTS"

<!--
  Notes for the author (delete before finishing):
  - Fill this spec from /speckit-specify. Focus on WHAT users need and WHY —
    not HOW it will be implemented. Technology and module layout belong in plan.md.
  - User stories should be INDEPENDENTLY testable: each story can ship alone and
    still deliver value. In a multi-module project each story typically maps to one
    feature module (see ARCHITECTURE.md §8), which is what makes independent
    shipping possible.
  - Maximum 3 [NEEDS CLARIFICATION] markers; make informed guesses for everything else
    and record them under Assumptions.
-->

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user story in plain language: who the user is, what they want, and what
happens. Keep it technology-agnostic.]

**Why this priority**: [explanation of the value and why it outranks other stories]

**Independent Test**: [describe how this story can be verified on its own — e.g. "run the
feature's test target and the isolated preview with mocked dependencies"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user story in plain language.]

**Why this priority**: [explanation]

**Independent Test**: [describe]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

- [ ] US1 can be fully tested independently (P1 only MVP)
- [ ] US2 can be fully tested independently
- [ ] US3 can be fully tested independently *(remove if not needed)*

### Edge Cases

<!--
  Action required: list edge cases the spec must handle. In this architecture most
  edge cases end up as reducer test cases, so being explicit here pays off directly.
-->

- [Edge case: what happens when …?]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST [specific, testable capability]
- **FR-002**: The system MUST [specific, testable capability]
- **FR-003**: The system MUST [specific, testable capability]

*Example of marking an unclear requirement:*

- **FR-006**: [NEEDS CLARIFICATION: exact retry policy when …]

### Key Entities *(include if the feature involves data)*

- **[Entity 1]**: [What it represents, key attributes, relationships — no implementation
  details]
- **[Entity 2]**: [What it represents]

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g. "Users can complete X in under N seconds"]
- **SC-002**: [Measurable metric, e.g. "Feature state is fully covered by its test target"]
- **SC-003**: [Qualitative measure, e.g. "Screens render identically in preview and app"]

## Assumptions

- [Documented informed guesses taken in place of clarification, e.g. "Data retention
  follows industry-standard practice"]

## Out of Scope

- [Explicitly excluded from this feature]
