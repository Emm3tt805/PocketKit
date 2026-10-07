import SwiftUI
import UserNotifications

struct RemindersView: View {
    @State private var title = ""
    @State private var message = ""
    @State private var date = Date().addingTimeInterval(300)
    @State private var daily = false
    @State private var pending: [UNNotificationRequest] = []
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                if status == .denied {
                    Section {
                        Text("Notifications are turned off for PocketKit.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                Section("New notification") {
                    TextField("Title", text: $title)
                    TextField("Message (optional)", text: $message, axis: .vertical)
                    DatePicker("When", selection: $date, in: Date()...)
                    Toggle("Repeat every day", isOn: $daily)
                    Button("Schedule") {
                        NotificationManager.shared.schedule(title: title, body: message, at: date, repeatsDaily: daily)
                        title = ""
                        message = ""
                        Task { await refresh() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section {
                    Button("Send a test notification in 5 seconds") {
                        NotificationManager.shared.schedule(title: "👋 Test", body: "Notifications are working!", after: 5)
                        Task { await refresh() }
                    }
                }

                Section("Scheduled") {
                    if pending.isEmpty {
                        Text("Nothing scheduled").foregroundStyle(.secondary)
                    }
                    ForEach(pending, id: \.identifier) { request in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.content.title).font(.headline)
                            if !request.content.body.isEmpty {
                                Text(request.content.body).font(.subheadline)
                            }
                            Text(describe(request))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { NotificationManager.shared.cancel(id: pending[i].identifier) }
                        pending.remove(atOffsets: offsets)
                    }
                }
            }
            .navigationTitle("Notifications")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private func refresh() async {
        let requests = await NotificationManager.shared.pending()
        let auth = await NotificationManager.shared.authorizationStatus()
        await MainActor.run {
            pending = requests.sorted { nextDate($0) < nextDate($1) }
            status = auth
        }
    }

    private func nextDate(_ request: UNNotificationRequest) -> Date {
        if let t = request.trigger as? UNCalendarNotificationTrigger { return t.nextTriggerDate() ?? .distantFuture }
        if let t = request.trigger as? UNTimeIntervalNotificationTrigger { return t.nextTriggerDate() ?? .distantFuture }
        return .distantFuture
    }

    private func describe(_ request: UNNotificationRequest) -> String {
        let next = nextDate(request)
        guard next != .distantFuture else { return "" }
        let when = next.formatted(date: .abbreviated, time: .shortened)
        return request.trigger?.repeats == true ? "Every day · next \(when)" : when
    }
}
