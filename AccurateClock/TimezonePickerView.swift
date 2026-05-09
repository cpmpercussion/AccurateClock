import SwiftUI

struct TimezonePickerView: View {
    @Binding var selectedIdentifier: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(
                        title: "System",
                        trailing: TimeZone.current.identifier,
                        isSelected: selectedIdentifier.isEmpty
                    ) {
                        selectedIdentifier = ""
                        dismiss()
                    }
                }

                ForEach(WorldTime.groupedByOffset, id: \.offsetMinutes) { group in
                    Section(group.offsetLabel) {
                        ForEach(group.cities) { city in
                            cityRow(city)
                        }
                    }
                }
            }
            .navigationTitle("Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func cityRow(_ city: WorldTimeCity) -> some View {
        Button {
            selectedIdentifier = city.identifier
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(city.code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)
                Text(city.city)
                    .foregroundStyle(.primary)
                Spacer()
                if city.identifier == selectedIdentifier {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(city.identifier)
    }

    @ViewBuilder
    private func row(title: String, trailing: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Text(trailing)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TimezonePickerView(selectedIdentifier: .constant(""))
}

#Preview("with Sydney selected") {
    TimezonePickerView(selectedIdentifier: .constant("Australia/Sydney"))
}
