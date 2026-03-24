import Foundation

enum NoteTemplate: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case meetingNotes = "Meeting Notes"
    case oneOnOne = "1:1 Meeting"
    case standup = "Stand-up"
    case retrospective = "Sprint Retrospective"
    case kickoff = "Project Kick-Off"
    case salesCall = "Sales Call"
    case customerDiscovery = "Customer Discovery"
    case userInterview = "User Interview"
    case pipelineReview = "Pipeline Review"
    case investorPitch = "Investor Pitch"
    case boardMeeting = "Board Meeting"
    case brainstorm = "Brainstorm"
    case designReview = "Design Review"
    case allHands = "All Hands"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .auto: return "sparkles"
        case .meetingNotes: return "doc.text"
        case .oneOnOne: return "person.2"
        case .standup: return "figure.stand"
        case .retrospective: return "arrow.counterclockwise"
        case .kickoff: return "flag"
        case .salesCall: return "phone"
        case .customerDiscovery: return "magnifyingglass"
        case .userInterview: return "mic"
        case .pipelineReview: return "chart.bar"
        case .investorPitch: return "dollarsign.circle"
        case .boardMeeting: return "building.columns"
        case .brainstorm: return "lightbulb"
        case .designReview: return "paintbrush"
        case .allHands: return "person.3"
        }
    }

    var promptSuffix: String {
        switch self {
        case .auto:
            return "Auto-detect the best structure for these notes."
        case .meetingNotes:
            return "Structure as: Key Discussion Points, Decisions Made, Action Items, Next Steps."
        case .oneOnOne:
            return "Structure as: Check-in, Discussion Topics, Feedback, Action Items, Personal Notes."
        case .standup:
            return "Structure as: What I Did Yesterday, What I'm Doing Today, Blockers."
        case .retrospective:
            return "Structure as: What Went Well, What Could Be Improved, Action Items."
        case .kickoff:
            return "Structure as: Project Overview, Goals & Success Metrics, Roles & Responsibilities, Timeline, Risks, Next Steps."
        case .salesCall:
            return "Structure as: Prospect Overview, Pain Points, Solution Fit, Objections, Next Steps, Deal Notes."
        case .customerDiscovery:
            return "Structure as: Customer Profile, Problems Discussed, Current Solutions, Insights, Opportunities."
        case .userInterview:
            return "Structure as: Participant Background, Key Quotes, Pain Points, Feature Requests, Insights."
        case .pipelineReview:
            return "Structure as: Deal Updates, At Risk, Won/Lost, Forecast, Action Items."
        case .investorPitch:
            return "Structure as: Pitch Highlights, Questions Asked, Concerns Raised, Follow-up Items, Investor Sentiment."
        case .boardMeeting:
            return "Structure as: Agenda Items, Discussion Summary, Decisions, Votes, Action Items."
        case .brainstorm:
            return "Structure as: Problem Statement, Ideas Generated, Top Ideas to Explore, Next Steps."
        case .designReview:
            return "Structure as: Design Overview, Feedback, Approved Changes, Remaining Questions, Next Steps."
        case .allHands:
            return "Structure as: Company Updates, Team Highlights, Q&A, Announcements."
        }
    }
}
