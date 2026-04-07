// CategoryEditorView.swift — Balance Horizon
// Allows users to add, reorder, and delete custom transaction categories.

import SwiftUI
import SwiftData

struct CategoryEditorView: View {
    @Query private var settingsArray: [AppSettings]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newCategory = ""

    private var settings: AppSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            List {
                Section("Add Category") {
                    HStack {
                        TextField("Category name", text: $newCategory)
                        Button {
                            guard !newCategory.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            settings?.categories.append(newCategory.trimmingCharacters(in: .whitespaces))
                            newCategory = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Categories") {
                    ForEach(settings?.categories ?? [], id: \.self) { cat in
                        Text(cat)
                    }
                    .onDelete { offsets in
                        settings?.categories.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        settings?.categories.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
