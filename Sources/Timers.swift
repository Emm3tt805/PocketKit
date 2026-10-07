import SwiftUI

struct TimerItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var duration: TimeInterval
    var remaining: TimeInterval
    var endDate: Date?          // set while the timer is running

    var isRunning: Bool { endDate != nil }

    func timeLeft(at now: Date) -> TimeInterval {
        if let end = endDate { return max(0, end.timeIntervalSince(now)) }
        return remaining
    }
}

final class TimerStore: ObservableObject {
    @Published var timers: [TimerItem] = [] { didSet { save() } }
    private let key = "pocketkit.timers"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([TimerItem].self, from: data) {
            timers = saved
        }
    }

    @discardableResult
    func add(name: String, seconds: TimeInterval) -> TimerItem {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let item = TimerItem(name: trimmed.isEmpty ? "Timer" : trimmed, duration: seconds, remaining: seconds)
        timers.append(item)
        return item
    }

    func start(_ timer: TimerItem) {
        guard let i = index(of: timer), timers[i].endDate == nil else { return }
        var item = timers[i]
        if item.remaining <= 0 { item.remaining = item.duration }
        item.endDate = Date().addingTimeInterval(item.remaining)
        timers[i] = item
        NotificationManager.shared.schedule(id: item.id.uuidString,
                                            title: "⏰ \(item.name)",
                                            body: "Your timer is done!",
                                            after: item.remaining)
    }

    func pause(_ timer: TimerItem) {
        guard let i = index(of: timer), let end = timers[i].endDate else { return }
        timers[i].remaining = max(0, end.timeIntervalSinceNow)
        timers[i].endDate = nil
        NotificationManager.shared.cancel(id: timer.id.uuidString)
    }

    func reset(_ timer: TimerItem) {
        guard let i = index(of: timer) else { return }
        timers[i].endDate = nil
        timers[i].remaining = timers[i].duration
        NotificationManager.shared.cancel(id: timer.id.uuidString)
    }

    func delete(at offsets: IndexSet) {
        for i in offsets { NotificationManager.shared.cancel(id: timers[i].id.uuidString) }
        timers.remove(atOffsets: offsets)
    }

    private func index(of timer: TimerItem) -> Int? {
        timers.firstIndex { $0.id == timer.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

func formatTime(_ t: TimeInterval) -> String {
    let s = Int(t.rounded(.up))
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
}

struct TimersView: View {
    @EnvironmentObject var store: TimerStore
    @State private var showAdd = false
    private let presets = [1, 5, 10, 25, 60]

    var body: some View {
        NavigationStack {
            List {
                Section("Quick start") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(presets, id: \.self) { minutes in
                                Button("\(minutes) min") {
                                    let t = store.add(name: "\(minutes) min timer", seconds: TimeInterval(minutes * 60))
                                    store.start(t)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Timers") {
                    if store.timers.isEmpty {
                        Text("No timers yet. Tap + to make one.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.timers) { timer in
                        TimerRow(timer: timer)
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .navigationTitle("Timers")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) {
                AddTimerSheet()
            }
        }
    }
}

struct TimerRow: View {
    @EnvironmentObject var store: TimerStore
    let timer: TimerItem

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let left = timer.timeLeft(at: context.date)
            let done = timer.isRunning && left <= 0

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(timer.name).font(.headline)
                    Text(done ? "Done!" : formatTime(left))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(done ? Color.green : Color.primary)
                    ProgressView(value: min(timer.duration, timer.duration - left), total: max(timer.duration, 1))
                        .tint(done ? .green : .accentColor)
                }
                Spacer()
                if !done {
                    Button {
                        timer.isRunning ? store.pause(timer) : store.start(timer)
                    } label: {
                        Image(systemName: timer.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.borderless)
                }
                Button {
                    store.reset(timer)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 6)
        }
    }
}

struct AddTimerSheet: View {
    @EnvironmentObject var store: TimerStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name (e.g. Pasta)", text: $name)
                HStack(spacing: 0) {
                    wheel($hours, 0..<24, "h")
                    wheel($minutes, 0..<60, "m")
                    wheel($seconds, 0..<60, "s")
                }
                .frame(height: 170)
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let total = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                        let t = store.add(name: name, seconds: total)
                        store.start(t)
                        dismiss()
                    }
                    .disabled(hours + minutes + seconds == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func wheel(_ value: Binding<Int>, _ range: Range<Int>, _ unit: String) -> some View {
        Picker(unit, selection: value) {
            ForEach(range, id: \.self) { Text("\($0) \(unit)").tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
