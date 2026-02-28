import Foundation

// MARK: - Models

struct CanvasAssignment: Identifiable {
    let id: Int
    let title: String
    let courseName: String
    let dueAt: Date?
    let htmlURL: URL?
    let isSubmitted: Bool
    let isMissing: Bool
    let pointsPossible: Double?
    let type: String   // "assignment", "quiz", "discussion_topic"
}

// MARK: - Codable helpers (planner/items response)

private struct PlannerItem: Codable {
    let plannableId: Int
    let plannableType: String
    let courseId: Int?
    let plannable: Plannable
    let submissions: SubmissionStatus?

    enum CodingKeys: String, CodingKey {
        case plannableId   = "plannable_id"
        case plannableType = "plannable_type"
        case courseId      = "course_id"
        case plannable, submissions
    }
}

private struct Plannable: Codable {
    let id: Int
    let title: String
    let dueAt: Date?
    let htmlUrl: String?
    let pointsPossible: Double?

    enum CodingKeys: String, CodingKey {
        case id, title
        case dueAt           = "due_at"
        case htmlUrl         = "html_url"
        case pointsPossible  = "points_possible"
    }
}

private struct SubmissionStatus: Codable {
    let submitted: Bool?
    let missing: Bool?
}

private struct CanvasCourse: Codable {
    let id: Int
    let name: String
}

// MARK: - Mock data (shown when no Canvas token is configured)

extension CanvasAssignment {
    static let mock: [CanvasAssignment] = {
        let cal = Calendar.current
        // Anchor to Feb 28 2026 (today) — offsets are days from that date
        let base = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        func d(_ month: Int, _ day: Int, _ hour: Int = 23, _ min: Int = 59) -> Date {
            cal.date(from: DateComponents(year: 2026, month: month, day: day,
                                          hour: hour, minute: min))!
        }
        return [
            // March 1
            CanvasAssignment(id: 1,  title: "S4 Poll",
                             courseName: "UROP / Seminar",    dueAt: d(3,1,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 1,   type: "quiz"),
            // March 3
            CanvasAssignment(id: 2,  title: "ENV - Life Cycle Assessment",
                             courseName: "ENVS 1000",         dueAt: d(3,3,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 10,  type: "assignment"),
            // March 4
            CanvasAssignment(id: 3,  title: "Homework 1",
                             courseName: "COMP 4332",         dueAt: d(3,4,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 100, type: "assignment"),
            CanvasAssignment(id: 4,  title: "Lab 2 Submission",
                             courseName: "COMP 4332",         dueAt: d(3,4,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 20,  type: "assignment"),
            // March 5
            CanvasAssignment(id: 5,  title: "1p Quiz L06",
                             courseName: "COMP 4332",         dueAt: d(3,5,13,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 1,   type: "quiz"),
            CanvasAssignment(id: 6,  title: "3p L06 Exercise",
                             courseName: "COMP 4332",         dueAt: d(3,5,15,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 3,   type: "assignment"),
            // March 6
            CanvasAssignment(id: 7,  title: "1p Quiz L07",
                             courseName: "COMP 4332",         dueAt: d(3,6,13,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 1,   type: "quiz"),
            CanvasAssignment(id: 8,  title: "3p L07 Exercise",
                             courseName: "COMP 4332",         dueAt: d(3,6,15,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 3,   type: "assignment"),
            // March 9
            CanvasAssignment(id: 9,  title: "Seminar Reflection",
                             courseName: "UROP / Seminar",    dueAt: d(3,9,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 10,  type: "assignment"),
            // March 12
            CanvasAssignment(id: 10, title: "Activity 1 - Phase 1",
                             courseName: "COMP 4222",         dueAt: d(3,12,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 40,  type: "assignment"),
            CanvasAssignment(id: 11, title: "6p Activity 1 - Phase 1",
                             courseName: "COMP 4222",         dueAt: d(3,12,18,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 6,   type: "assignment"),
            CanvasAssignment(id: 12, title: "6p Activity 2 - Submission",
                             courseName: "COMP 4222",         dueAt: d(3,12,18,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 6,   type: "assignment"),
            // March 18
            CanvasAssignment(id: 13, title: "9p Mar18 Attendance",
                             courseName: "UROP / Seminar",    dueAt: d(3,18,21,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 9,   type: "assignment"),
            CanvasAssignment(id: 14, title: "[2026.3.11] Reflection",
                             courseName: "UROP / Seminar",    dueAt: d(3,18,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            // March 25
            CanvasAssignment(id: 15, title: "9p Mar25 Attendance",
                             courseName: "UROP / Seminar",    dueAt: d(3,25,21,0),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 9,   type: "assignment"),
            CanvasAssignment(id: 16, title: "[2026.3.18] Submission",
                             courseName: "UROP / Seminar",    dueAt: d(3,25,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            // March 29
            CanvasAssignment(id: 17, title: "Midterm Project (Report)",
                             courseName: "COMP 4222",         dueAt: d(3,29,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 50,  type: "assignment"),
            CanvasAssignment(id: 18, title: "Midterm Project (Presentation)",
                             courseName: "COMP 4332",         dueAt: d(3,29,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 50,  type: "assignment"),
            CanvasAssignment(id: 19, title: "Project Phase 1",
                             courseName: "COMP 4222",         dueAt: d(3,29,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 30,  type: "assignment"),
            // March 31
            CanvasAssignment(id: 20, title: "L06 Extended Bonus",
                             courseName: "COMP 4332",         dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            CanvasAssignment(id: 21, title: "L07 PageRank",
                             courseName: "COMP 4332",         dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            CanvasAssignment(id: 22, title: "L08 HITS Algorithm",
                             courseName: "COMP 4332",         dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            CanvasAssignment(id: 23, title: "L09 Performance Metrics",
                             courseName: "COMP 4332",         dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            CanvasAssignment(id: 24, title: "L10 Benchmarking",
                             courseName: "COMP 4332",         dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
            CanvasAssignment(id: 25, title: "Second Seminar Reflection",
                             courseName: "UROP / Seminar",    dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 10,  type: "assignment"),
            CanvasAssignment(id: 26, title: "[2026.3.25] Reflection",
                             courseName: "UROP / Seminar",    dueAt: d(3,31,23,59),
                             htmlURL: nil, isSubmitted: false, isMissing: false, pointsPossible: 5,   type: "assignment"),
        ]
        .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
    }()
}

// MARK: - Client

@MainActor
final class CanvasClient: ObservableObject {
    @Published var assignments:  [CanvasAssignment] = []
    @Published var isLoading   = false
    @Published var errorMsg:   String? = nil
    @Published var usingMock   = false

    // Configurable — defaults to HKUST
    var baseURL = UserDefaults.standard.string(forKey: "canvas_url")   ?? "https://canvas.ust.hk"
    var token   = UserDefaults.standard.string(forKey: "canvas_token") ?? ""

    private var courseNames: [Int: String] = [:]

    // MARK: - Public

    func fetch() async {
        // No token → show mock data immediately
        guard !token.isEmpty else {
            assignments = CanvasAssignment.mock
            usingMock   = true
            errorMsg    = nil
            return
        }

        isLoading = true
        errorMsg  = nil
        usingMock = false

        do {
            try await loadCourses()
            let items = try await loadPlannerItems()

            let allowed = Set(["assignment", "quiz", "discussion_topic"])
            let fetched = items
                .filter { allowed.contains($0.plannableType) }
                .filter { !($0.submissions?.submitted ?? false) }
                .map { item -> CanvasAssignment in
                    let course = item.courseId.flatMap { courseNames[$0] } ?? "—"
                    let url    = item.plannable.htmlUrl.flatMap { URL(string: $0) }
                    return CanvasAssignment(
                        id:             item.plannable.id,
                        title:          item.plannable.title,
                        courseName:     course,
                        dueAt:          item.plannable.dueAt,
                        htmlURL:        url,
                        isSubmitted:    item.submissions?.submitted ?? false,
                        isMissing:      item.submissions?.missing   ?? false,
                        pointsPossible: item.plannable.pointsPossible,
                        type:           item.plannableType
                    )
                }
                .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }

            // Fall back to mock if Canvas returned nothing
            if fetched.isEmpty {
                assignments = CanvasAssignment.mock
                usingMock   = true
            } else {
                assignments = fetched
            }
        } catch {
            // Network/auth error → fall back to mock, surface the error as a banner
            assignments = CanvasAssignment.mock
            usingMock   = true
            errorMsg    = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private

    private func loadCourses() async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/courses?enrollment_state=active&per_page=100") else { return }
        let (data, _) = try await request(url: url)
        let courses   = try JSONDecoder().decode([CanvasCourse].self, from: data)
        for c in courses { courseNames[c.id] = c.name }
    }

    private func loadPlannerItems() async throws -> [PlannerItem] {
        let fmt    = ISO8601DateFormatter()
        let start  = fmt.string(from: Date())
        let end    = fmt.string(from: Calendar.current.date(byAdding: .day, value: 45, to: Date())!)
        guard let url = URL(string:
            "\(baseURL)/api/v1/planner/items?start_date=\(start)&end_date=\(end)&per_page=100") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await request(url: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "Canvas", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) — \(body.prefix(80))"])
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PlannerItem].self, from: data)
    }

    private func request(url: URL) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await URLSession.shared.data(for: req)
    }
}
