import Domain
import Testing

struct ProgramDraftTests {
    @Test func programNameIsTrimmedAndRequired() {
        #expect(ProgramDraft(name: "  Сила 3×  ").trimmedName == "Сила 3×")
        #expect(ProgramDraft(name: "Сила 3×").isValid)
        #expect(ProgramDraft(name: "   ").validationIssues == [.emptyName])
    }

    @Test func dayLabelIsOptionalAndShort() {
        #expect(ProgramDayDraft(name: "Грудь и трицепс", label: "  ").trimmedLabel == nil)
        #expect(ProgramDayDraft(name: "Грудь и трицепс", label: " A ").trimmedLabel == "A")
        #expect(ProgramDayDraft(name: "Грудь и трицепс", label: "A1Б").isValid)
        #expect(ProgramDayDraft(name: "Грудь и трицепс", label: "Пятн").validationIssues == [.labelTooLong])
    }

    @Test func dayNameIsRequired() {
        #expect(ProgramDayDraft(name: " ", label: "A").validationIssues == [.emptyName])
    }
}
