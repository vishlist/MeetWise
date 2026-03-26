import Foundation

/// Built-in note templates for different meeting types
struct TemplateService {
    static let templates: [NoteTemplate] = [
        NoteTemplate(name: "Blank", icon: "doc", category: .basic, content: ""),
        NoteTemplate(name: "Meeting Notes", icon: "note.text", category: .basic, content: "# Meeting Notes\n\n## Attendees\n- \n\n## Agenda\n1. \n\n## Discussion\n- \n\n## Action Items\n- [ ] \n\n## Next Steps\n- "),
        NoteTemplate(name: "1:1 Meeting", icon: "person.2", category: .oneOnOne, content: "# 1:1 Meeting\n\n## Check-in\n- How are things going?\n\n## Updates\n- \n\n## Blockers\n- \n\n## Career Development\n- \n\n## Action Items\n- [ ] "),
        NoteTemplate(name: "Sprint Planning", icon: "arrow.triangle.2.circlepath", category: .agile, content: "# Sprint Planning\n\n## Sprint Goal\n\n\n## User Stories\n- [ ] Story 1 (X points)\n- [ ] Story 2 (X points)\n\n## Risks & Dependencies\n- \n\n## Total Points: "),
        NoteTemplate(name: "Standup", icon: "sunrise", category: .agile, content: "# Daily Standup\n\n## Yesterday\n- \n\n## Today\n- \n\n## Blockers\n- "),
        NoteTemplate(name: "Retrospective", icon: "arrow.counterclockwise", category: .agile, content: "# Retrospective\n\n## What went well 🎉\n- \n\n## What could improve 🔧\n- \n\n## Action items 🎯\n- [ ] "),
        NoteTemplate(name: "Design Review", icon: "paintbrush", category: .design, content: "# Design Review\n\n## Design Being Reviewed\n\n\n## Feedback\n### Visual\n- \n### UX\n- \n### Accessibility\n- \n\n## Changes Requested\n- [ ] \n\n## Approved: Yes / No"),
        NoteTemplate(name: "Client Call", icon: "phone", category: .external, content: "# Client Call\n\n## Client:\n## Attendees:\n\n## Agenda\n1. \n\n## Discussion\n- \n\n## Client Requests\n- \n\n## Commitments Made\n- [ ] \n\n## Follow Up By:"),
        NoteTemplate(name: "Interview", icon: "person.badge.plus", category: .hr, content: "# Interview Notes\n\n## Candidate:\n## Role:\n\n## Technical Skills (1-5):\n## Communication (1-5):\n## Culture Fit (1-5):\n\n## Notes\n- \n\n## Recommendation: Hire / No Hire / Maybe"),
        NoteTemplate(name: "Product Review", icon: "shippingbox", category: .product, content: "# Product Review\n\n## Feature/Product:\n## Status:\n\n## Demo Notes\n- \n\n## Feedback\n- \n\n## Decisions\n- \n\n## Next Steps\n- [ ] "),
        NoteTemplate(name: "Brainstorm", icon: "lightbulb", category: .creative, content: "# Brainstorm Session\n\n## Topic:\n\n## Ideas\n1. \n2. \n3. \n\n## Top 3 to Pursue\n1. \n2. \n3. \n\n## Next Steps\n- [ ] "),
        NoteTemplate(name: "Project Kickoff", icon: "flag", category: .project, content: "# Project Kickoff\n\n## Project Name:\n## Timeline:\n## Team:\n\n## Goals\n- \n\n## Scope\n- In scope:\n- Out of scope:\n\n## Milestones\n1. \n2. \n\n## Risks\n- "),
        NoteTemplate(name: "Sales Call", icon: "dollarsign.circle", category: .sales, content: "# Sales Call\n\n## Prospect:\n## Company:\n## Stage:\n\n## Pain Points\n- \n\n## Our Solution\n- \n\n## Objections\n- \n\n## Next Steps\n- [ ] \n\n## Deal Value: $"),
        NoteTemplate(name: "Board Meeting", icon: "building.2", category: .external, content: "# Board Meeting\n\n## Financial Update\n- \n\n## Key Metrics\n- \n\n## Strategic Decisions\n- \n\n## Risks & Concerns\n- \n\n## Action Items\n- [ ] ")
    ]

    enum TemplateCategory: String, CaseIterable {
        case basic = "Basic"
        case oneOnOne = "1:1"
        case agile = "Agile"
        case design = "Design"
        case external = "External"
        case hr = "HR"
        case product = "Product"
        case creative = "Creative"
        case project = "Project"
        case sales = "Sales"
    }
}

struct NoteTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: TemplateService.TemplateCategory
    let content: String
}
