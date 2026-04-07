// CSVExporter.swift — Balance Horizon
// CSV export service for transactions and monthly reports.

import Foundation

struct CSVExporter {

    // MARK: - Date Formatter

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Field Escaping

    /// Escapes a CSV field by wrapping in quotes if it contains commas, quotes, or newlines.
    /// Internal quotes are doubled per RFC 4180.
    private static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    // MARK: - Export Transactions

    /// Generates a CSV string from an array of transactions.
    /// Columns: Date, Description, Category, Type, Amount, Recurring, Frequency
    static func exportTransactions(_ transactions: [Transaction]) -> String {
        var lines: [String] = []
        lines.append("Date,Description,Category,Type,Amount,Recurring,Frequency")

        for transaction in transactions {
            let date = dateFormatter.string(from: transaction.date)
            let description = escapeField(transaction.desc)
            let category = escapeField(transaction.category)
            let type = escapeField(transaction.type.rawValue)
            let amount = String(format: "%.2f", transaction.amount)
            let recurring = transaction.isRecurring ? "Yes" : "No"
            let frequency = transaction.recurringFrequency?.rawValue ?? ""

            let row = [date, description, category, type, amount, recurring, frequency]
                .joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Export Monthly Report

    /// Generates a CSV with a daily running balance for a given month.
    /// Columns: Date, Starting Balance, Income, Expenses, Ending Balance
    static func exportMonthlyReport(transactions: [Transaction], month: Date, startingBalance: Double) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return ""
        }

        var lines: [String] = []
        lines.append("Date,Starting Balance,Income,Expenses,Ending Balance")

        var runningBalance = startingBalance

        for day in range {
            guard let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDay) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: currentDate)
            let dayTransactions = transactions.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }

            let dayIncome = dayTransactions
                .filter { $0.type == .income }
                .reduce(0.0) { $0 + $1.amount }

            let dayExpenses = dayTransactions
                .filter { $0.type == .expense }
                .reduce(0.0) { $0 + $1.amount }

            let dayStartBalance = runningBalance
            runningBalance += dayIncome - dayExpenses

            let dateString = dateFormatter.string(from: currentDate)
            let row = [
                dateString,
                String(format: "%.2f", dayStartBalance),
                String(format: "%.2f", dayIncome),
                String(format: "%.2f", dayExpenses),
                String(format: "%.2f", runningBalance)
            ].joined(separator: ",")

            lines.append(row)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Temporary File

    /// Writes CSV content to a temporary file and returns the file URL for sharing.
    static func generateTemporaryFile(csv: String, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename).appendingPathExtension("csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
