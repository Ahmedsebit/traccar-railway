# Tracking Platform: Team Handover Pack

**Prepared:** November 1, 2026  
**Programme:** November 1, 2026-April 30, 2027  
**Receiving team:** Two junior engineers, responsible for backend integration and support  
**Scope:** Tracker connectivity and decoding through Traccar, Carribu ingestion, trip tracking, operational diagnostics and user alerts  
**Status:** Proposed programme; approval and readiness gates remain open

## Read this first

| Document | Use |
|---|---|
| [Six-month plan](SIX-MONTH-PLAN.md) | Monthly outcomes, 26 weekly work packages, learning, ownership and review gates |
| [Technical notes](TECHNICAL-NOTES.md) | Inspected architecture, configuration, contracts, limitations and primary references |
| [Operations and best practices](OPERATIONS-AND-BEST-PRACTICES.md) | Safe setup, TDD, releases, incident triage, recovery and support templates |
| [Testing and acceptance](TESTING-AND-ACCEPTANCE.md) | Synthetic scenarios, evidence levels, measurements and acceptance checklist |

Start with the technical notes, then use the plan to create small backlog items.
Every item needs a primary owner, a reviewer, an expected outcome and evidence.
Keep the documents updated when the corresponding code or deployment changes.

This repository is a Traccar deployment wrapper, not the upstream Java server
source. The full platform crosses separate repositories. References such as
`carribu_backend\services\trackerIngestion.js` are workspace paths, not files
contained in this repository. Arrange access to each required repository.

The companion workspace document, `CARRIBU-HANDOVER-AND-ONBOARDING.md`, covers
general full-stack and native-mobile onboarding. This pack supplements it with
tracking-specific operational ownership; it does not transfer every mobile,
web or product feature to these two engineers.

## Ownership to assign before production responsibility

| Role | Proposed responsibility | Assignment |
|---|---|---|
| Engineer A | Initial integration primary; operational backup | Receiving team to assign |
| Engineer B | Initial testing/support primary; integration backup | Receiving team to assign |
| Experienced engineering/operations owner | High-risk review, production approval, escalations and recovery decisions | Required; not yet named |
| Product/school operations owner | Alert semantics, operational expectations and emergency communication | Required; not yet named |
| Mobile/web owners | Client contracts, permissions, presentation and releases | Confirm existing owners |
| Data/account owner | Access, retention, provider accounts, quotas and secret custody | Required; not yet named |

Rotate the juniors' primary/backup roles monthly. They can review routine work
for each other, but neither is the sole approver of their own high-risk change.
If experienced review is unavailable, continue training and non-production
work; do not treat the calendar as authorization to deploy.

## First-day checklist

- [ ] Name the experienced reviewer, incident escalation contact and backup.
- [ ] Agree working/support hours; do not assume two juniors provide 24/7 cover.
- [ ] Confirm which applications and tracker models are actually supported.
- [ ] Inventory deployed versions, repositories, accounts and environment owners.
- [ ] Arrange disposable training databases and mock notification receivers.
- [ ] Agree who can approve deployment, database recovery and tracker commands.
- [ ] Record unresolved decisions in the technical notes' approval ledger.
- [ ] Demonstrate one synthetic trip and one failure using the approved environment.

## Evidence and safety boundaries

The technical notes describe local files inspected on November 1, 2026.
Deployed settings, hardware behavior, capacity and handset delivery were not
verified for this pack. Planned tests and targets are not completed results.

Do not put real student/guardian data, device routes, credentials, tokens,
service-account contents or signing keys in documentation or training fixtures.
Use mock providers by default. Production replay, tracker reconfiguration,
paid lookups and releases require separate approval.

GPS positions and push notifications are operational information, not proof
of a student's safety or attendance. Follow the organization's established
operational and emergency procedures when safety is in question.
