import SwiftUI
import AppKit

// MARK: - TodoView

struct TodoView: View {
    @StateObject private var client = CanvasClient()
    @State private var showConfig   = false
    @State private var doneIDs:  Set<Int> = []

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if client.isLoading {
                Spacer()
                ProgressView("Fetching assignments…").padding()
                Spacer()

            } else if let err = client.errorMsg {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Open Settings") { showConfig = true }
                        .buttonStyle(.borderedProminent)
                }
                Spacer()

            } else if client.assignments.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.headline)
                    Text("No upcoming unsubmitted assignments\nin the next 45 days.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()

            } else {
                assignmentList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 18, x: 6, y: 0)
        .sheet(isPresented: $showConfig) {
            CanvasConfigSheet { reload() }
        }
        .onAppear { reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "checklist")
                .foregroundStyle(Color.accentColor)
                .font(.system(size: 15, weight: .semibold))
            Text("Assignments")
                .font(.system(size: 15, weight: .semibold))

            if !client.isLoading && !client.assignments.isEmpty {
                Text("\(client.assignments.filter { !doneIDs.contains($0.id) }.count) remaining")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            if client.usingMock {
                Text("DEMO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.orange, in: Capsule())
                    .help("No Canvas token set — showing sample data. Tap ⚙ to connect.")
            }

            Spacer()

            Button {
                Task { await client.fetch() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Refresh")

            Button { showConfig = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Canvas settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - List

    private var assignmentList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                let grouped = groupedAssignments()
                ForEach(grouped, id: \.0) { label, items in
                    Section {
                        ForEach(items) { item in
                            AssignmentRow(
                                item:        item,
                                isDone:      doneIDs.contains(item.id),
                                onToggle:    { toggle(item.id) }
                            )
                            Divider().padding(.leading, 44)
                        }
                    } header: {
                        sectionHeader(label)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(VisualEffectView(material: .menu))
    }

    // MARK: - Helpers

    private func groupedAssignments() -> [(String, [CanvasAssignment])] {
        let cal = Calendar.current
        let now = Date()

        var overdue:   [CanvasAssignment] = []
        var today:     [CanvasAssignment] = []
        var thisWeek:  [CanvasAssignment] = []
        var later:     [CanvasAssignment] = []
        var undated:   [CanvasAssignment] = []

        for item in client.assignments {
            guard !doneIDs.contains(item.id) || true else { continue }
            guard let due = item.dueAt else { undated.append(item); continue }

            if due < now {
                overdue.append(item)
            } else if cal.isDateInToday(due) {
                today.append(item)
            } else if cal.isDate(due, equalTo: now, toGranularity: .weekOfYear) {
                thisWeek.append(item)
            } else {
                later.append(item)
            }
        }

        return [
            ("Overdue",   overdue),
            ("Today",     today),
            ("This Week", thisWeek),
            ("Upcoming",  later),
            ("No Due Date", undated)
        ].filter { !$1.isEmpty }
    }

    private func toggle(_ id: Int) {
        if doneIDs.contains(id) { doneIDs.remove(id) } else { doneIDs.insert(id) }
    }

    private func reload() {
        client.baseURL = UserDefaults.standard.string(forKey: "canvas_url")   ?? "https://canvas.ust.hk"
        client.token   = UserDefaults.standard.string(forKey: "canvas_token") ?? ""
        Task { await client.fetch() }
    }
}

// MARK: - Assignment Row

struct AssignmentRow: View {
    let item:     CanvasAssignment
    let isDone:   Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    private var urgencyColor: Color {
        guard let due = item.dueAt else { return .primary }
        if item.isMissing              { return .red }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        if days < 0  { return .red    }
        if days <= 1 { return .orange }
        if days <= 3 { return Color(red: 0.9, green: 0.7, blue: 0) }
        return .secondary
    }

    private var dueLabel: String {
        guard let due = item.dueAt else { return "No due date" }
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .full
        return fmt.localizedString(for: due, relativeTo: Date())
    }

    private var typeIcon: String {
        switch item.type {
        case "quiz":             return "questionmark.circle"
        case "discussion_topic": return "bubble.left.and.bubble.right"
        default:                 return "doc.text"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            // Body
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(item.courseName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .strikethrough(isDone, color: .secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if item.isMissing {
                        Label("Missing", systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.red, in: Capsule())
                    }

                    Text(dueLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(urgencyColor)

                    if let pts = item.pointsPossible, pts > 0 {
                        Text("· \(Int(pts)) pts")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Open in Canvas
            if isHovered, let url = item.htmlURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open in Canvas")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? Color.primary.opacity(0.04) : .clear)
        .onHover { isHovered = $0 }
        .opacity(isDone ? 0.5 : 1)
    }
}

// MARK: - Canvas Config Sheet

struct CanvasConfigSheet: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var url:   String = UserDefaults.standard.string(forKey: "canvas_url")   ?? "https://canvas.ust.hk"
    @State private var token: String = UserDefaults.standard.string(forKey: "canvas_token") ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Canvas LMS")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Label("Canvas URL", systemImage: "globe")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("https://canvas.ust.hk", text: $url)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Access Token", systemImage: "key.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                SecureField("Paste your Canvas access token", text: $token)
                    .textFieldStyle(.roundedBorder)
                Text("Canvas → Account → Settings → Approved Integrations → New Access Token")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save & Fetch") {
                    UserDefaults.standard.set(url,   forKey: "canvas_url")
                    UserDefaults.standard.set(token, forKey: "canvas_token")
                    dismiss()
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || token.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 400)
    }
}
