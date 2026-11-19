import Charts
import SwiftUI

/// "Your machine" — the Atelier's details and its care schedule.
struct MachineCareSection: View {
    let machine: OwnedMachine
    var onStartCare: (CareTask) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your machine")

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "cube")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.burgundy)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Color.amber.opacity(0.3)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(machine.name) · \(machine.room)")
                            .textStyle(.bodyStrong)
                            .foregroundStyle(Color.ink)
                        Text("\(machine.model) · Firmware \(machine.firmware)")
                            .textStyle(.caption)
                            .foregroundStyle(Color.inkSoft)
                    }
                    Spacer()
                }
                .accessibilityElement(children: .combine)

                Rectangle().fill(Color.line).frame(height: 1).padding(.vertical, 14)

                VStack(spacing: 14) {
                    ForEach(machine.care) { task in
                        CareTaskRow(task: task) { onStartCare(task) }
                    }
                }

                Text("Serial \(machine.serial)")
                    .font(BrandFont.body(11, relativeTo: .caption2))
                    .foregroundStyle(Color.inkSoft)
                    .textSelection(.enabled)
                    .padding(.top, 14)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 12)
        }
    }
}

struct CareTaskRow: View {
    let task: CareTask
    var onStart: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: task.systemImage)
                .font(.system(size: 16))
                .foregroundStyle(task.isDueSoon ? Color.terracottaDeep : Color.inkSoft)
                .frame(width: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title).textStyle(.bodyStrong).foregroundStyle(Color.ink)
                    Spacer()
                    Text(task.dueIn)
                        .textStyle(.caption)
                        .foregroundStyle(task.isDueSoon ? Color.terracottaDeep : Color.inkSoft)
                }
                LevelBar(value: task.remaining, fill: task.isDueSoon ? .amber : .terracotta, track: .paper3, height: 5)
                Text(task.detail)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if task.isDueSoon {
                    Button("Start \(task.title.lowercased())", action: onStart)
                        .buttonStyle(.pill(.outline, height: 34, horizontalPadding: 14))
                        .padding(.top, 4)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Eight weeks of flavour DNA as three lines (the home card shows only this week).
struct TasteHistoryChart: View {
    let weeks: [TasteWeek]

    private struct Point: Identifiable {
        let id = UUID()
        let week: Date
        let series: String
        let value: Double
    }

    private var points: [Point] {
        weeks.flatMap { week in
            [Point(week: week.weekStart, series: "Body", value: week.body),
             Point(week: week.weekStart, series: "Sweetness", value: week.sweetness),
             Point(week: week.weekStart, series: "Acidity", value: week.acidity)]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your flavour DNA")
            VStack(alignment: .leading, spacing: 12) {
                Text("Eight weeks drifting rounder and sweeter as the mornings cool.")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)

                Chart(points) { point in
                    LineMark(x: .value("Week", point.week, unit: .weekOfYear),
                             y: .value("Level", point.value))
                        .foregroundStyle(by: .value("Trait", point.series))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    if point.week == weeks.last?.weekStart {
                        PointMark(x: .value("Week", point.week, unit: .weekOfYear),
                                  y: .value("Level", point.value))
                            .foregroundStyle(by: .value("Trait", point.series))
                            .symbolSize(40)
                    }
                }
                .chartForegroundStyleScale([
                    "Body": Color.burgundy,
                    "Sweetness": Color.terracotta,
                    "Acidity": Color.amber,
                ])
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine().foregroundStyle(Color.line)
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v == 0 ? "Low" : (v == 1 ? "High" : ""))
                                    .font(BrandFont.body(10, relativeTo: .caption2))
                                    .foregroundStyle(Color.inkSoft)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(BrandFont.body(10, relativeTo: .caption2))
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
                .frame(height: 180)
                .accessibilityLabel("Flavour trends over eight weeks")
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 12)
        }
    }
}

#Preview {
    let overview = MockAccountService.sample(now: .now)
    return ScrollView {
        VStack(spacing: 28) {
            MachineCareSection(machine: overview.machine)
            TasteHistoryChart(weeks: overview.tasteHistory)
        }
        .padding(.vertical)
    }
    .background(Color.paper)
}
