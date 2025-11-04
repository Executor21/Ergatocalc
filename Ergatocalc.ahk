/*
Script: Ergatocalc
Συγγραφέας: Tasos
Έτος: 2025
MIT License
Copyright (c) 2025 Tasos
*/
#Requires AutoHotkey v2.0+ ; Απαίτηση έκδοσης AHK v2.0 ή νεότερη
#SingleInstance Force ; Επιτρέπει μόνο ένα αντίγραφο του script
SetWorkingDir(A_ScriptDir) ; Ορισμός τρέχοντος καταλόγου εργασίας
LoadOrCreateConfig() { ; Φόρτωση ή δημιουργία αρχείου ρυθμίσεων
cfgFile := "Wage_Config.cfg" ; Ορισμός διαδρομής αρχείου ρυθμίσεων
; Default values - Αυτές οι τιμές θα χρησιμοποιηθούν αν το αρχείο δεν υπάρχει
defaultBaseDaily := ["39.30", "37.07", "34.84", "31.85", "29.62", "29.04"] ; Προεπιλεγμένες βασικές ημερήσιες αποδοχές
defaultInsuranceRates := Map( ; Προεπιλεγμένοι συντελεστές ασφαλιστικών εισφορών
101, 0.1337,
102, 0.1337,
103, 0.1037,
104, 0.1037,
105, 0.1682,
106, 0.1682,
107, 0.1257,
108, 0.1257
)
; Αν το αρχείο δεν υπάρχει, δημιουργούμε ένα νέο με τις default τιμές
if !FileExist(cfgFile) { ; Έλεγχος αν υπάρχει το αρχείο ρυθμίσεων
try { ; Προσπάθεια δημιουργίας αρχείου αν δεν υπάρχει
; Δημιουργούμε έναν κενό φάκελο αν δεν υπάρχει
if !InStr(cfgFile, "\") && !InStr(cfgFile, "/") {
; Το αρχείο είναι στον τρέχοντα φάκελο
} else {
; Αν το αρχείο είναι σε υποφάκελο, δημιουργούμε τον φάκελο
DirCreate(SubStr(cfgFile, 1, InStr(cfgFile, "\", , -1)))
}
; Γράφουμε τις default τιμές
for index, value in defaultBaseDaily { ; Προεπιλεγμένες βασικές ημερήσιες αποδοχές
IniWrite(value, cfgFile, "BaseDailyWages", "Option" . index)
if (A_LastError != 0) {
throw Error("Αποτυχία εγγραφής BaseDailyWages")
}
}
for code, rate in defaultInsuranceRates { ; Προεπιλεγμένοι συντελεστές ασφαλιστικών εισφορών
formattedRate := Format("{:.4f}", rate)  ; Μορφοποίηση με 4 δεκαδικά
IniWrite(formattedRate, cfgFile, "InsuranceRates", code)
if (A_LastError != 0) {
throw Error("Αποτυχία εγγραφής InsuranceRates")
}
}
; Επιβεβαίωση ότι το αρχείο δημιουργήθηκε σωστά
if !FileExist(cfgFile) { ; Έλεγχος αν υπάρχει το αρχείο ρυθμίσεων
throw Error("Το αρχείο ρυθμίσεων δεν δημιουργήθηκε")
}
; Εμφάνιση ενημερωτικού μηνύματος μόνο την πρώτη φορά
static firstRun := true
if (firstRun) {
MsgBox("Δημιουργήθηκε νέο αρχείο ρυθμίσεων με default τιμές.`n`nΘα βρίσκεται εδώ:`n" A_ScriptDir "\" cfgFile, "Πληροφορία", "Iconi")
firstRun := false
}
} catch as e {
; Αν αποτύχει η δημιουργία, χρησιμοποιούμε τις default τιμές χωρίς σφάλμα
MsgBox("Προσοχή: Δεν ήταν δυνατή η δημιουργία αρχείου ρυθμίσεων.`nΘα χρησιμοποιηθούν οι προεπιλεγμένες τιμές.`n`nΛεπτομέρεια σφάλματος: " e.Message, "Προσοχή", "Icon!")
return {baseDaily: defaultBaseDaily, insuranceRates: defaultInsuranceRates} ; Προεπιλεγμένες βασικές ημερήσιες αποδοχές
}
}
; Διαβάζουμε τις ρυθμίσεις από το αρχείο
config := {baseDaily: [], insuranceRates: Map()} ; Δημιουργία χάρτη με κωδικούς και ποσοστά εισφορών
configReadSuccess := true
; Διαβάζουμε τα βασικά ημερομίσθια
loop {
value := IniRead(cfgFile, "BaseDailyWages", "Option" . A_Index, "")
if (value == "") {
; Αν δεν βρεθούν τιμές, χρησιμοποιούμε τις default
if (A_Index == 1) {
configReadSuccess := false
config.baseDaily := defaultBaseDaily ; Προεπιλεγμένες βασικές ημερήσιες αποδοχές
}
break
}
config.baseDaily.Push(value)
}
; Διαβάζουμε τους συντελεστές ασφάλισης
loop 8 {
code := 100 + A_Index
rate := IniRead(cfgFile, "InsuranceRates", code, "")
if (rate == "") {
configReadSuccess := false
break
}
config.insuranceRates[code] := Number(rate)
}
; Επαλήθευση των διαβασμένων τιμών
if (!configReadSuccess || config.baseDaily.Length == 0 || config.insuranceRates.Count == 0) {
MsgBox("Προσοχή: Το αρχείο ρυθμίσεων είναι κατεστραμμένο ή ελλιπές.`nΘα χρησιμοποιηθούν οι προεπιλεγμένες τιμές.", "Προσοχή", "Icon!")
; Διαγράφουμε το κατεστραμμένο αρχείο και δημιουργούμε νέο
try { ; Προσπάθεια δημιουργίας αρχείου αν δεν υπάρχει
FileDelete(cfgFile)
return LoadOrCreateConfig() ; Αναδρομική κλήση για δημιουργία νέου αρχείου
} catch {
return {baseDaily: defaultBaseDaily, insuranceRates: defaultInsuranceRates} ; Προεπιλεγμένες βασικές ημερήσιες αποδοχές
}
}
return config
}
; Κύριο πρόγραμμα - ξεκινά απευθείας
MAIN_PROGRAM()
MAIN_PROGRAM() {
; Load configuration πρώτα
config := LoadOrCreateConfig()
global insuranceRates := config.insuranceRates
TraySetIcon("Shell32.dll", 44)
; ----------
; GUI STYLING
; ----------
MyGui := Gui()
MyGui.SetFont("s10", "Segoe UI")
MyGui.BackColor := "FFFFFF"
MyGui.Opt("-Resize +MaximizeBox +MinimizeBox")
; Create Tab control with 4 tabs
TabCtrl := MyGui.AddTab3("x10 y10 w1320 h720", ["Μισθοδοσία", "Δώρο Χριστουγέννων", "Δώρο Πάσχα", "Επίδομα Αδείας"])
; ----------
; Helper Functions
; ----------
CreateInfoIcon(guiObj, x, y, tooltipText) {
; Χρησιμοποιούμε Text με Unicode character ⓘ αντί για Picture
infoIcon := guiObj.AddText("x" x " y" y " w16 h23 +0x200", "ⓘ")  ; 0x200 = SS_CENTERIMAGE
infoIcon.SetFont("s10 bold", "Segoe UI")
infoIcon.OnEvent("Click", (*) => MsgBox(tooltipText, "Πληροφορία", "Iconi"))
infoIcon.ToolTip := "Κάντε κλικ για πληροφορίες"
return infoIcon
}
CreateHourDropdown(guiObj, x, y, text, helpText) {
hourOptions := ["0"]
Loop 240 {
hourOptions.Push(A_Index)
}
guiObj.AddText("x" x " y" y " w200 h23", text)
ctrl := guiObj.AddDropDownList("x" x+230 " y" y " w100 r20 Choose1", hourOptions)
CreateInfoIcon(guiObj, x+340, y, helpText)
return ctrl
}
; ----------
; BASIC INFORMATION SECTION (MAIN TAB)
; ----------
TabCtrl.UseTab(1)

; ΚΟΥΜΠΙΑ - Κάτω δεξιά
CalculateBtn := MyGui.AddButton("x860 y40 w460 h50 Default", "ΥΠΟΛΟΓΙΣΜΟΣ ΜΙΣΘΟΥ")
SaveBtn1 := MyGui.AddButton("x860 y100 w225 h40", "ΑΠΟΘΗΚΕΥΣΗ")
InfoBtn1 := MyGui.AddButton("x1095 y100 w225 h40", "INFO")

; OUTPUT SECTION - Δεξιά
OutputSectionCtrl := MyGui.AddEdit("x860 y150 w460 h540 ReadOnly BackgroundFFFCE6 Border +VScroll")

; ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ - Αριστερά πάνω
BasicInfoGrp := MyGui.AddGroupBox("x20 y40 w400 h300", "Βασικά Στοιχεία")
BasicInfoGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

MyGui.AddText("x30 y70 w180 h23", "Ημέρες του μήνα:")
daysOptions := []
Loop 30 {
    daysOptions.Push(A_Index)
}
DaysCtrl := MyGui.AddDropDownList("x260 y70 w100 r20 Choose26", daysOptions)
CreateInfoIcon(MyGui, 370, 70, "Επιλέξτε τον αριθμό των ημερών εργασίας για τον μήνα. Για εργατοτεχνίτη υπολογίστε τις ημέρες Δευτέρα εως Σάββατο.")

MyGui.AddText("x30 y103 w180 h23", "Παντρεμένος:")
MarriedCtrl := MyGui.AddCheckBox("x260 y103 w30 h23")
CreateInfoIcon(MyGui, 300, 103, "Επιλέξτε αν ο εργαζόμενος είναι παντρεμένος. Προσθέτει 10% επί του βασικού μισθού.")

MyGui.AddText("x30 y136 w180 h23", "Τριετίες (0-6):")
trienniaOptions := [0,1,2,3,4,5,6]
TrienniaCtrl := MyGui.AddDropDownList("x260 y136 w100 r7 Choose1", trienniaOptions)
CreateInfoIcon(MyGui, 370, 136, "Επιλέξτε τον αριθμό των τριετιών (0-6). Κάθε τριετία προσθέτει 5% επί του βασικού ημερομισθίου.")

MyGui.AddText("x30 y169 w180 h23", "Μικτό Ημερομίσθιο:")
DailyGrossCtrl := MyGui.AddEdit("x260 y169 w100 h23 ", "39.3")
CreateInfoIcon(MyGui, 370, 169, "Εισάγετε το μικτό ημερομίσθιο. Πρέπει να είναι αριθμητική τιμή (π.χ. 39.3).")

MyGui.AddText("x30 y202 w180 h23", "Βασικό Ημερομίσθιο:")
BaseDailyCtrl := MyGui.AddDropDownList("x260 y202 w100 r6 Choose1", config.baseDaily)
CreateInfoIcon(MyGui, 370, 202, "Επιλέξτε το βασικό ημερομίσθιο.")

MyGui.AddText("x30 y235 w180 h23", "Κωδικός Ενσήμων:")
InsurancePackageCtrl := MyGui.AddDropDownList("x260 y235 w100 r8 Choose6", [101,102,103,104,105,106,107,108])
CreateInfoIcon(MyGui, 370, 235, "Κωδικοί ασφάλισης 101-108")

MyGui.AddText("x30 y268 w180 h23", "Αριθμός Παιδιών:")
childrenOptions := [0,1,2,3,4,5,6,7,8,9,10]
ChildrenCtrl := MyGui.AddDropDownList("x260 y268 w100 r11 Choose1", childrenOptions)
CreateInfoIcon(MyGui, 370, 268, "Ο αριθμός των παιδιών για φορολογική έκπτωση")

MyGui.AddText("x30 y301 w180 h23", "Επιδοτούμενος (Ε.Ε.Ε):")
IsSubsidizedCtrl := MyGui.AddCheckBox("x260 y301 w30 h23")
CreateInfoIcon(MyGui, 300, 301, "Επιλέξτε αν ο εργαζόμενος λαμβάνει επιδότηση από το Ε.Ε.Ε (μειώνει τις εισφορές).")

; ----------
; REGULAR ALLOWANCES SECTION (MAIN TAB)
; ----------
RegAllowGrp := MyGui.AddGroupBox("x20 y350 w400 h340", "Κανονικές Προσαυξήσεις")
RegAllowGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

OvertimeDayHoursCtrl := CreateHourDropdown(MyGui, 30, 380, "Υπερεργασία (ώρες):", "Υπερεργασία με 20% προσαύξηση.")
LegalOvertimeDayHoursCtrl := CreateHourDropdown(MyGui, 30, 413, "Υπερωρία (ώρες):", "Νόμιμη υπερωρία με 40% προσαύξηση.")
NightHoursCtrl := CreateHourDropdown(MyGui, 30, 446, "Νυχτερινή Απασχόληση (ώρες):", "Νυχτερινή εργασία με 25% προσαύξηση.")
NightOvertimeHoursCtrl := CreateHourDropdown(MyGui, 30, 479, "Νυχτερινή Υπερεργασία (ώρες):", "Νυχτερινή υπερεργασία με 25% + 20% προσαύξηση.")
NightLegalOvertimeHoursCtrl := CreateHourDropdown(MyGui, 30, 512, "Νυχτερινή Υπερωρία (ώρες):", "Νυχτερινή νόμιμη υπερωρία με 25% + 40% προσαύξηση.")
SundayHolidayHoursCtrl := CreateHourDropdown(MyGui, 30, 545, "Κυριακή/Αργία (ώρες):", "Εργασία Κυριακής/Αργίας με 75% προσαύξηση.")

; ----------
; SPECIAL ALLOWANCES (6TH DAY) (MAIN TAB)
; ----------
SpecAllow6Grp := MyGui.AddGroupBox("x430 y40 w420 h330", "Ειδικές Προσαυξήσεις (6η ημέρα)")
SpecAllow6Grp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

SixthDayOvertimeHoursCtrl := CreateHourDropdown(MyGui, 440, 70, "6ης ημέρα (ώρες):", "Υπερωρία 6ης ημέρας με 30% προσαύξηση.")
NightSixthDayHoursCtrl := CreateHourDropdown(MyGui, 440, 103, "Νυχτερινό 6η ημέρας (ώρες):", "Νυχτερινή εργασία 6ης ημέρας με 25% + 30% προσαύξηση.")
SundayHolidaySixthDayHoursCtrl := CreateHourDropdown(MyGui, 440, 136, "Κυριακή/Αργία 6η ημέρας (ώρες):", "Κυριακή/Αργία 6ης ημέρας με 75% + 30% προσαύξηση.")
NightSundaySixthDayHoursCtrl := CreateHourDropdown(MyGui, 440, 169, "Νύχτα/Κυριακή 6η ημέρας (ώρες):", "Νυχτερινή Κυριακή 6ης ημέρας με 100% + 30% προσαύξηση.")

; ----------
; SPECIAL ALLOWANCES (SUNDAYS/HOLIDAYS) (MAIN TAB)
; ----------
SpecAllowSunGrp := MyGui.AddGroupBox("x430 y380 w420 h310", "Ειδικές Προσαυξήσεις (Κυριακές/Αργίες)")
SpecAllowSunGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

SundayHolidayOvertimeHoursCtrl := CreateHourDropdown(MyGui, 440, 410, "Κυριακή/Αργία Υπερεργασία (ώρες):", "Υπερεργασία Κυριακής/Αργίας με 75% + 20% προσαύξηση.")
SundayHolidayLegalOvertimeHoursCtrl := CreateHourDropdown(MyGui, 440, 443, "Κυριακή/Αργία Υπερωρία (ώρες):", "Νόμιμη υπερωρία Κυριακής/Αργίας με 75% + 40% προσαύξηση.")
NightSundayHoursCtrl := CreateHourDropdown(MyGui, 440, 476, "Νυχτερινό Κυριακή (ώρες):", "Νυχτερινή Κυριακή με 100% προσαύξηση.")
NightSundayOvertimeHoursCtrl := CreateHourDropdown(MyGui, 440, 509, "Νύχτα/Κυριακή Υπερεργασία (ώρες):", "Νυχτερινή υπερεργασία Κυριακής με 100% + 20% προσαύξηση.")
NightSundayLegalOvertimeHoursCtrl := CreateHourDropdown(MyGui, 440, 542, "Νύχτα/Κυριακή Υπερωρία (ώρες):", "Νυχτερινή νόμιμη υπερωρία Κυριακής με 100% + 40% προσαύξηση.")

; ----------
; CHRISTMAS BONUS TAB
; ----------
TabCtrl.UseTab(2)

; Christmas Bonus Days Coefficient Map
XmasCoefficients := Map(
    1, 0.1053, 2, 0.2105, 3, 0.3158, 4, 0.4211, 5, 0.5263, 6, 0.6316, 7, 0.7368, 8, 0.8421, 9, 0.9474, 10, 1.0526,
    11, 1.1579, 12, 1.2632, 13, 1.3684, 14, 1.4737, 15, 1.5789, 16, 1.6842, 17, 1.7895, 18, 1.8947, 19, 2, 20, 2.1053,
    21, 2.2105, 22, 2.3158, 23, 2.4211, 24, 2.5263, 25, 2.6316, 26, 2.7368, 27, 2.8421, 28, 2.9474, 29, 3.0526, 30, 3.1579,
    31, 3.2632, 32, 3.3684, 33, 3.4737, 34, 3.5789, 35, 3.6842, 36, 3.7895, 37, 3.8947, 38, 4, 39, 4.1053, 40, 4.2105,
    41, 4.3158, 42, 4.4211, 43, 4.5263, 44, 4.6316, 45, 4.7368, 46, 4.8421, 47, 4.9474, 48, 5.0526, 49, 5.1579, 50, 5.2632,
    51, 5.3684, 52, 5.4737, 53, 5.5789, 54, 5.6842, 55, 5.7895, 56, 5.8947, 57, 6, 58, 6.1053, 59, 6.2105, 60, 6.3158,
    61, 6.4211, 62, 6.5263, 63, 6.6316, 64, 6.7368, 65, 6.8421, 66, 6.9474, 67, 7.0526, 68, 7.1579, 69, 7.2632, 70, 7.3684,
    71, 7.4737, 72, 7.5789, 73, 7.6842, 74, 7.7895, 75, 7.8947, 76, 8, 77, 8.1053, 78, 8.2105, 79, 8.3158, 80, 8.4211,
    81, 8.5263, 82, 8.6316, 83, 8.7368, 84, 8.8421, 85, 8.9474, 86, 9.0526, 87, 9.1579, 88, 9.2632, 89, 9.3684, 90, 9.4737,
    91, 9.5789, 92, 9.6842, 93, 9.7895, 94, 9.8947, 95, 10, 96, 10.1053, 97, 10.2105, 98, 10.3158, 99, 10.4211, 100, 10.5263,
    101, 10.6316, 102, 10.7368, 103, 10.8421, 104, 10.9474, 105, 11.0526, 106, 11.1579, 107, 11.2632, 108, 11.3684, 109, 11.4737, 110, 11.5789,
    111, 11.6842, 112, 11.7895, 113, 11.8947, 114, 12, 115, 12.1053, 116, 12.2105, 117, 12.3158, 118, 12.4211, 119, 12.5263, 120, 12.6316,
    121, 12.7368, 122, 12.8421, 123, 12.9474, 124, 13.0526, 125, 13.1579, 126, 13.2632, 127, 13.3684, 128, 13.4737, 129, 13.5789, 130, 13.6842,
    131, 13.7895, 132, 13.8947, 133, 14, 134, 14.1053, 135, 14.2105, 136, 14.3158, 137, 14.4211, 138, 14.5263, 139, 14.6316, 140, 14.7368,
    141, 14.8421, 142, 14.9474, 143, 15.0526, 144, 15.1579, 145, 15.2632, 146, 15.3684, 147, 15.4737, 148, 15.5789, 149, 15.6842, 150, 15.7895,
    151, 15.8947, 152, 16, 153, 16.1053, 154, 16.2105, 155, 16.3158, 156, 16.4211, 157, 16.5263, 158, 16.6316, 159, 16.7368, 160, 16.8421,
    161, 16.9474, 162, 17.0526, 163, 17.1579, 164, 17.2632, 165, 17.3684, 166, 17.4737, 167, 17.5789, 168, 17.6842, 169, 17.7895, 170, 17.8947,
    171, 18, 172, 18.1053, 173, 18.2105, 174, 18.3158, 175, 18.4211, 176, 18.5263, 177, 18.6316, 178, 18.7368, 179, 18.8421, 180, 18.9474,
    181, 19.0526, 182, 19.1579, 183, 19.2632, 184, 19.3684, 185, 19.4737, 186, 19.5789, 187, 19.6842, 188, 19.7895, 189, 19.8947, 190, 20,
    191, 20.1053, 192, 20.2105, 193, 20.3158, 194, 20.4211, 195, 20.5263, 196, 20.6316, 197, 20.7368, 198, 20.8421, 199, 20.9474, 200, 21.0526,
    201, 21.1579, 202, 21.2632, 203, 21.3684, 204, 21.4737, 205, 21.5789, 206, 21.6842, 207, 21.7895, 208, 21.8947, 209, 22, 210, 22.1053,
    211, 22.2105, 212, 22.3158, 213, 22.4211, 214, 22.5263, 215, 22.6316, 216, 22.7368, 217, 22.8421, 218, 22.9474, 219, 23.0526, 220, 23.1579,
    221, 23.2632, 222, 23.3684, 223, 23.4737, 224, 23.5789, 225, 23.6842, 226, 23.7895, 227, 23.8947, 228, 24, 229, 24.1053, 230, 24.2105,
    231, 24.3158, 232, 24.4211, 233, 24.5263, 234, 24.6316, 235, 24.7368, 236, 24.8421, 237, 24.9474, 238, 25, 239, 25, 240, 25
)

; ΚΟΥΜΠΙΑ - Δεξιά πάνω
XmasCalculateBtn := MyGui.AddButton("x670 y40 w650 h50 Default", "ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ ΧΡΙΣΤΟΥΓΕΝΝΩΝ")
SaveBtn2 := MyGui.AddButton("x670 y100 w320 h40", "ΑΠΟΘΗΚΕΥΣΗ")
InfoBtn2 := MyGui.AddButton("x1000 y100 w320 h40", "INFO")

; OUTPUT SECTION - Δεξιά
XmasOutputSectionCtrl := MyGui.AddEdit("x670 y150 w650 h540 ReadOnly BackgroundFFFCE6 Border +VScroll")

; BASIC INFORMATION SECTION (CHRISTMAS BONUS TAB) - Αριστερά
XmasBasicInfoGrp := MyGui.AddGroupBox("x20 y40 w630 h340", "Βασικά Στοιχεία Δώρου Χριστουγέννων")
XmasBasicInfoGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

MyGui.AddText("x30 y70 w280 h23", "Ημέρες απασχόλησης από 1/5 έως 31/12:")
XmasDaysCtrl := MyGui.AddDropDownList("x320 y70 w100 r10 AltSubmit", [])
Loop 240 {
    XmasDaysCtrl.Add([A_Index])
}
XmasDaysCtrl.Text := 240
CreateInfoIcon(MyGui, 430, 70, "Επιλέξτε τον αριθμό των ημερών απασχόλησης από 1/5 έως 31/12.")

MyGui.AddText("x30 y103 w180 h23", "Παντρεμένος:")
XmasMarriedCtrl := MyGui.AddCheckBox("x320 y103 w30 h23")
CreateInfoIcon(MyGui, 360, 103, "Επιλέξτε αν ο εργαζόμενος είναι παντρεμένος. Προσθέτει 10% επί του βασικού μισθού.")

MyGui.AddText("x30 y136 w180 h23", "Τριετίες (0-6):")
XmasTrienniaCtrl := MyGui.AddDropDownList("x320 y136 w100 r7 Choose1", trienniaOptions)
CreateInfoIcon(MyGui, 430, 136, "Επιλέξτε τον αριθμό των τριετιών (0-6). Κάθε τριετία προσθέτει 5% επί του βασικού ημερομισθίου.")

MyGui.AddText("x30 y169 w180 h23", "Μικτό Ημερομίσθιο:")
XmasDailyGrossCtrl := MyGui.AddEdit("x320 y169 w100 h23 ", "39.3")
CreateInfoIcon(MyGui, 430, 169, "Εισάγετε το μικτό ημερομίσθιο. Πρέπει να είναι αριθμητική τιμή (π.χ. 39.3).")

MyGui.AddText("x30 y202 w180 h23", "Βασικό Ημερομίσθιο:")
XmasBaseDailyCtrl := MyGui.AddDropDownList("x320 y202 w100 r6 Choose1", config.baseDaily)
CreateInfoIcon(MyGui, 430, 202, "Επιλέξτε το βασικό ημερομίσθιο.")

MyGui.AddText("x30 y235 w280 h23", "Σύνολο Προσαυξήσεων (Μάιος-Νοέμβριος):")
XmasOvertimeBonusCtrl := MyGui.AddEdit("x320 y235 w100 h23 ", "0")
CreateInfoIcon(MyGui, 430, 235, "Εισάγετε το συνολικό ποσό προσαυξήσεων για την περίοδο Μάιος-Νοέμβριος. Θα διαιρεθεί με 8 και θα προστεθεί στο δώρο.")

MyGui.AddText("x30 y268 w180 h23", "Κωδικός Ενσήμων:")
XmasInsurancePackageCtrl := MyGui.AddDropDownList("x320 y268 w100 r8 Choose6", [101,102,103,104,105,106,107,108])
CreateInfoIcon(MyGui, 430, 268, "Κωδικοί ασφάλισης 101-108")

MyGui.AddText("x30 y301 w180 h23", "Αριθμός Παιδιών:")
XmasChildrenCtrl := MyGui.AddDropDownList("x320 y301 w100 r11 Choose1", childrenOptions)
CreateInfoIcon(MyGui, 430, 301, "Ο αριθμός των παιδιών για φορολογική έκπτωση")

MyGui.AddText("x30 y334 w180 h23", "Επιδοτούμενος (Ε.Ε.Ε):")
XmasIsSubsidizedCtrl := MyGui.AddCheckBox("x320 y334 w30 h23")
CreateInfoIcon(MyGui, 360, 334, "Επιλέξτε αν ο εργαζόμενος λαμβάνει επιδότηση από το Ε.Ε.Ε (μειώνει τις εισφορές).")

; ----------
; EASTER BONUS TAB
; ----------
TabCtrl.UseTab(3)

; Easter Bonus Days Coefficient Map
EasterCoefficients := Map(
    1, 0.125, 2, 0.25, 3, 0.375, 4, 0.5, 5, 0.625, 6, 0.75, 7, 0.875, 8, 1, 9, 1.125, 10, 1.25,
    11, 1.375, 12, 1.5, 13, 1.625, 14, 1.75, 15, 1.875, 16, 2, 17, 2.125, 18, 2.25, 19, 2.375, 20, 2.5,
    21, 2.625, 22, 2.75, 23, 2.875, 24, 3, 25, 3.125, 26, 3.25, 27, 3.375, 28, 3.5, 29, 3.625, 30, 3.75,
    31, 3.875, 32, 4, 33, 4.125, 34, 4.25, 35, 4.375, 36, 4.5, 37, 4.625, 38, 4.75, 39, 4.875, 40, 5,
    41, 5.125, 42, 5.25, 43, 5.375, 44, 5.5, 45, 5.625, 46, 5.75, 47, 5.875, 48, 6, 49, 6.125, 50, 6.25,
    51, 6.375, 52, 6.5, 53, 6.625, 54, 6.75, 55, 6.875, 56, 7, 57, 7.125, 58, 7.25, 59, 7.375, 60, 7.5,
    61, 7.625, 62, 7.75, 63, 7.875, 64, 8, 65, 8.125, 66, 8.25, 67, 8.375, 68, 8.5, 69, 8.625, 70, 8.75,
    71, 8.875, 72, 9, 73, 9.125, 74, 9.25, 75, 9.375, 76, 9.5, 77, 9.625, 78, 9.75, 79, 9.875, 80, 10,
    81, 10.125, 82, 10.25, 83, 10.375, 84, 10.5, 85, 10.625, 86, 10.75, 87, 10.875, 88, 11, 89, 11.125, 90, 11.25,
    91, 11.375, 92, 11.5, 93, 11.625, 94, 11.75, 95, 11.875, 96, 12, 97, 12.125, 98, 12.25, 99, 12.375, 100, 12.5,
    101, 12.625, 102, 12.75, 103, 12.875, 104, 13, 105, 13.125, 106, 13.25, 107, 13.375, 108, 13.5, 109, 13.625, 110, 13.75,
    111, 13.875, 112, 14, 113, 14.125, 114, 14.25, 115, 14.375, 116, 14.5, 117, 14.625, 118, 14.75, 119, 14.875, 120, 15
)

; ΚΟΥΜΠΙΑ - Δεξιά πάνω
EasterCalculateBtn := MyGui.AddButton("x670 y40 w650 h50 Default", "ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ ΠΑΣΧΑ")
SaveBtn3 := MyGui.AddButton("x670 y100 w320 h40", "ΑΠΟΘΗΚΕΥΣΗ")
InfoBtn3 := MyGui.AddButton("x1000 y100 w320 h40", "INFO")

; OUTPUT SECTION - Δεξιά
EasterOutputSectionCtrl := MyGui.AddEdit("x670 y150 w650 h540 ReadOnly BackgroundFFFCE6 Border +VScroll")

; BASIC INFORMATION SECTION (EASTER BONUS TAB) - Αριστερά
EasterBasicInfoGrp := MyGui.AddGroupBox("x20 y40 w630 h340", "Βασικά Στοιχεία Δώρου Πάσχα")
EasterBasicInfoGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

MyGui.AddText("x30 y70 w280 h23", "Ημέρες απασχόλησης από 1/1 έως 30/4:")
EasterDaysCtrl := MyGui.AddDropDownList("x320 y70 w100 r10 AltSubmit", [])
Loop 120 {
    EasterDaysCtrl.Add([A_Index])
}
EasterDaysCtrl.Text := 120
CreateInfoIcon(MyGui, 430, 70, "Επιλέξτε τον αριθμό των ημερών απασχόλησης από 1/1 έως 30/4.")

MyGui.AddText("x30 y103 w180 h23", "Παντρεμένος:")
EasterMarriedCtrl := MyGui.AddCheckBox("x320 y103 w30 h23")
CreateInfoIcon(MyGui, 360, 103, "Επιλέξτε αν ο εργαζόμενος είναι παντρεμένος. Προσθέτει 10% επί του βασικού μισθού.")

MyGui.AddText("x30 y136 w180 h23", "Τριετίες (0-6):")
EasterTrienniaCtrl := MyGui.AddDropDownList("x320 y136 w100 r7 Choose1", trienniaOptions)
CreateInfoIcon(MyGui, 430, 136, "Επιλέξτε τον αριθμό των τριετιών (0-6). Κάθε τριετία προσθέτει 5% επί του βασικού ημερομισθίου.")

MyGui.AddText("x30 y169 w180 h23", "Μικτό Ημερομίσθιο:")
EasterDailyGrossCtrl := MyGui.AddEdit("x320 y169 w100 h23 ", "39.3")
CreateInfoIcon(MyGui, 430, 169, "Εισάγετε το μικτό ημερομίσθιο. Πρέπει να είναι αριθμητική τιμή (π.χ. 39.3).")

MyGui.AddText("x30 y202 w180 h23", "Βασικό Ημερομίσθιο:")
EasterBaseDailyCtrl := MyGui.AddDropDownList("x320 y202 w100 r6 Choose1", config.baseDaily)
CreateInfoIcon(MyGui, 430, 202, "Επιλέξτε το βασικό ημερομίσθιο.")

MyGui.AddText("x30 y235 w280 h23", "Σύνολο Προσαυξήσεων (Ιανουάριος-Απρίλιος):")
EasterOvertimeBonusCtrl := MyGui.AddEdit("x320 y235 w100 h23 ", "0")
CreateInfoIcon(MyGui, 430, 235, "Εισάγετε το συνολικό ποσό προσαυξήσεων για την περίοδο Ιανουάριος-Απρίλιος. Θα διαιρεθεί με 4 και θα προστεθεί στο δώρο.")

MyGui.AddText("x30 y268 w180 h23", "Κωδικός Ενσήμων:")
EasterInsurancePackageCtrl := MyGui.AddDropDownList("x320 y268 w100 r8 Choose6", [101,102,103,104,105,106,107,108])
CreateInfoIcon(MyGui, 430, 268, "Κωδικοί ασφάλισης 101-108")

MyGui.AddText("x30 y301 w180 h23", "Αριθμός Παιδιών:")
EasterChildrenCtrl := MyGui.AddDropDownList("x320 y301 w100 r11 Choose1", childrenOptions)
CreateInfoIcon(MyGui, 430, 301, "Ο αριθμός των παιδιών για φορολογική έκπτωση")

MyGui.AddText("x30 y334 w180 h23", "Επιδοτούμενος (Ε.Ε.Ε):")
EasterIsSubsidizedCtrl := MyGui.AddCheckBox("x320 y334 w30 h23")
CreateInfoIcon(MyGui, 360, 334, "Επιλέξτε αν ο εργαζόμενος λαμβάνει επιδότηση από το Ε.Ε.Ε (μειώνει τις εισφορές).")

; ----------
; LEAVE ALLOWANCE TAB
; ----------
TabCtrl.UseTab(4)

; ΚΟΥΜΠΙΑ - Δεξιά πάνω
LeaveCalculateBtn := MyGui.AddButton("x670 y40 w650 h50 Default", "ΥΠΟΛΟΓΙΣΜΟΣ ΕΠΙΔΟΜΑΤΟΣ ΑΔΕΙΑΣ")
SaveBtn4 := MyGui.AddButton("x670 y100 w320 h40", "ΑΠΟΘΗΚΕΥΣΗ")
InfoBtn4 := MyGui.AddButton("x1000 y100 w320 h40", "INFO")

; OUTPUT SECTION - Δεξιά
LeaveOutputSectionCtrl := MyGui.AddEdit("x670 y150 w650 h540 ReadOnly BackgroundFFFCE6 Border +VScroll")

; BASIC INFORMATION SECTION (LEAVE ALLOWANCE TAB) - Αριστερά
LeaveBasicInfoGrp := MyGui.AddGroupBox("x20 y40 w630 h300", "Βασικά Στοιχεία Επιδόματος Αδείας")
LeaveBasicInfoGrp.SetFont("Bold")
MyGui.SetFont(, "Segoe UI")

MyGui.AddText("x30 y70 w280 h23", "Ημέρες απασχόλησης:")
LeaveDaysCtrl := MyGui.AddDropDownList("x320 y70 w100 r13 AltSubmit", [])
Loop 13 {
    LeaveDaysCtrl.Add([A_Index])
}
LeaveDaysCtrl.Text := 13
CreateInfoIcon(MyGui, 430, 70, "Επιλέξτε τον αριθμό των ημερών απασχόλησης για το επίδομα αδείας (1-13).")

MyGui.AddText("x30 y103 w180 h23", "Παντρεμένος:")
LeaveMarriedCtrl := MyGui.AddCheckBox("x320 y103 w30 h23")
CreateInfoIcon(MyGui, 360, 103, "Επιλέξτε αν ο εργαζόμενος είναι παντρεμένος. Προσθέτει 10% επί του βασικού μισθού.")

MyGui.AddText("x30 y136 w180 h23", "Τριετίες (0-6):")
LeaveTrienniaCtrl := MyGui.AddDropDownList("x320 y136 w100 r7 Choose1", trienniaOptions)
CreateInfoIcon(MyGui, 430, 136, "Επιλέξτε τον αριθμό των τριετιών (0-6). Κάθε τριετία προσθέτει 5% επί του βασικού ημερομισθίου.")

MyGui.AddText("x30 y169 w180 h23", "Μικτό Ημερομίσθιο:")
LeaveDailyGrossCtrl := MyGui.AddEdit("x320 y169 w100 h23 ", "39.3")
CreateInfoIcon(MyGui, 430, 169, "Εισάγετε το μικτό ημερομίσθιο. Πρέπει να είναι αριθμητική τιμή (π.χ. 39.3).")

MyGui.AddText("x30 y202 w180 h23", "Βασικό Ημερομίσθιο:")
LeaveBaseDailyCtrl := MyGui.AddDropDownList("x320 y202 w100 r6 Choose1", config.baseDaily)
CreateInfoIcon(MyGui, 430, 202, "Επιλέξτε το βασικό ημερομίσθιο.")

MyGui.AddText("x30 y235 w180 h23", "Κωδικός Ενσήμων:")
LeaveInsurancePackageCtrl := MyGui.AddDropDownList("x320 y235 w100 r8 Choose6", [101,102,103,104,105,106,107,108])
CreateInfoIcon(MyGui, 430, 235, "Κωδικοί ασφάλισης 101-108")

MyGui.AddText("x30 y268 w180 h23", "Αριθμός Παιδιών:")
LeaveChildrenCtrl := MyGui.AddDropDownList("x320 y268 w100 r11 Choose1", childrenOptions)
CreateInfoIcon(MyGui, 430, 268, "Ο αριθμός των παιδιών για φορολογική έκπτωση")

MyGui.AddText("x30 y301 w180 h23", "Επιδοτούμενος (Ε.Ε.Ε):")
LeaveIsSubsidizedCtrl := MyGui.AddCheckBox("x320 y301 w30 h23")
CreateInfoIcon(MyGui, 360, 301, "Επιλέξτε αν ο εργαζόμενος λαμβάνει επιδότηση από το Ε.Ε.Ε (μειώνει τις εισφορές).")

; Return to main tab
TabCtrl.UseTab(1)

MyGui.Title := "Ergatocalc"
MyGui.Show("w1340 h740")
; ----------
; EVENT HANDLERS
; ----------
MyGui.OnEvent("Close", GuiCloseFunc)
CalculateBtn.OnEvent("Click", CalculateSalary)
XmasCalculateBtn.OnEvent("Click", CalculateXmasBonus)
EasterCalculateBtn.OnEvent("Click", CalculateEasterBonus)
LeaveCalculateBtn.OnEvent("Click", CalculateLeaveAllowance)
SaveBtn1.OnEvent("Click", (*) => SaveToFile("Μισθός", OutputSectionCtrl.Value))
SaveBtn2.OnEvent("Click", (*) => SaveToFile("Δώρο_Χριστουγέννων", XmasOutputSectionCtrl.Value))
SaveBtn3.OnEvent("Click", (*) => SaveToFile("Δώρο_Πάσχα", EasterOutputSectionCtrl.Value))
SaveBtn4.OnEvent("Click", (*) => SaveToFile("Επίδομα_Αδείας", LeaveOutputSectionCtrl.Value))
InfoBtn1.OnEvent("Click", ShowInfo)
InfoBtn2.OnEvent("Click", ShowInfo)
InfoBtn3.OnEvent("Click", ShowInfo)
InfoBtn4.OnEvent("Click", ShowInfo)
GuiCloseFunc(*) {
ExitApp
}
; ----------
; ΥΠΟΛΟΓΙΣΜΟΣ ΜΙΣΘΟΥ (ΟΡΙΣΜΟΣ ΤΗΣ ΣΥΝΑΡΤΗΣΗΣ)
; ----------
CalculateSalary(*) {
; Input Validation
if !RegExMatch(DailyGrossCtrl.Value, "^\d+(\.\d+)?$") {
MsgBox("Παρακαλώ εισάγετε έγκυρο μικτό ημερομίσθιο (π.χ. 39.3).")
return
}
; Get Values
dailyGross := Number(DailyGrossCtrl.Value)
days := Number(DaysCtrl.Text)
triennia := Number(TrienniaCtrl.Text)
children := Number(ChildrenCtrl.Text)
insurancePackage := Number(InsurancePackageCtrl.Text)
baseDaily := Number(BaseDailyCtrl.Text)
isMarried := MarriedCtrl.Value
isSubsidized := IsSubsidizedCtrl.Value
; Calculate Base Salary
currentGrossDaily := dailyGross
; Apply Marriage Bonus (10% of dailyGross)
marriageBonus := 0
if (isMarried) {
marriageBonus := Format("{:.2f}", dailyGross * 0.10)
currentGrossDaily += Number(marriageBonus)
}
; Apply Triennia Bonus (5% of baseDaily per triennia)
trienniaBonus := 0
if (triennia > 0) {
trienniaBonus := Round(Number(baseDaily) * 0.05 * triennia, 2)
currentGrossDaily += trienniaBonus
}
currentGrossDaily := Round(currentGrossDaily, 2)
; Hourly Wage Calculation
grossHourly := currentGrossDaily * 6 / 40
grossHourly := Number(Format("{:.4f}", grossHourly))  ; Διατήρηση 4 δεκαδικών για ακρίβεια
grossMonthly := currentGrossDaily * days
grossMonthly := Round(grossMonthly, 2)
; Calculate Allowances
overtimeDayHours := Number(OvertimeDayHoursCtrl.Text)
legalOvertimeDayHours := Number(LegalOvertimeDayHoursCtrl.Text)
nightHours := Number(NightHoursCtrl.Text)
nightOvertimeHours := Number(NightOvertimeHoursCtrl.Text)
nightLegalOvertimeHours := Number(NightLegalOvertimeHoursCtrl.Text)
sundayHolidayHours := Number(SundayHolidayHoursCtrl.Text)
sixthDayOvertimeHours := Number(SixthDayOvertimeHoursCtrl.Text)
nightSixthDayHours := Number(NightSixthDayHoursCtrl.Text)
sundayHolidaySixthDayHours := Number(SundayHolidaySixthDayHoursCtrl.Text)
nightSundaySixthDayHours := Number(NightSundaySixthDayHoursCtrl.Text)
sundayHolidayOvertimeHours := Number(SundayHolidayOvertimeHoursCtrl.Text)
sundayHolidayLegalOvertimeHours := Number(SundayHolidayLegalOvertimeHoursCtrl.Text)
nightSundayHours := Number(NightSundayHoursCtrl.Text)
nightSundayOvertimeHours := Number(NightSundayOvertimeHoursCtrl.Text)
nightSundayLegalOvertimeHours := Number(NightSundayLegalOvertimeHoursCtrl.Text)
; Calculate Allowance Amounts - χρήση Format για συνεπή εμφάνιση με 2 δεκαδικά
overtimeDayAmount := Format("{:.2f}", overtimeDayHours * grossHourly * 1.20)
legalOvertimeDayAmount := Format("{:.2f}", legalOvertimeDayHours * grossHourly * 1.40)
nightAmount := Format("{:.2f}", nightHours * grossHourly * 0.25)
nightOvertimeAmount := Format("{:.2f}", nightOvertimeHours * grossHourly * 1.25 * 1.20)
nightLegalOvertimeAmount := Format("{:.2f}", nightLegalOvertimeHours * grossHourly * 1.25 * 1.40)
sundayHolidayAmount := Format("{:.2f}", sundayHolidayHours * grossHourly * 0.75)
sixthDayOvertimeAmount := Format("{:.2f}", sixthDayOvertimeHours * grossHourly * 1.30)
nightSixthDayAmount := Format("{:.2f}", nightSixthDayHours * grossHourly * 1.25 * 1.30)
sundayHolidaySixthDayAmount := Format("{:.2f}", sundayHolidaySixthDayHours * grossHourly * 1.75 * 1.30)
nightSundaySixthDayAmount := Format("{:.2f}", nightSundaySixthDayHours * grossHourly * 2 * 1.30)
sundayHolidayOvertimeAmount := Format("{:.2f}", sundayHolidayOvertimeHours * grossHourly * 1.75 * 1.20)
sundayHolidayLegalOvertimeAmount := Format("{:.2f}", sundayHolidayLegalOvertimeHours * grossHourly * 1.75 * 1.40)
nightSundayAmount := Format("{:.2f}", nightSundayHours * grossHourly * 1)
nightSundayOvertimeAmount := Format("{:.2f}", nightSundayOvertimeHours * grossHourly * 2 * 1.20)
nightSundayLegalOvertimeAmount := Format("{:.2f}", nightSundayLegalOvertimeHours * grossHourly * 2 * 1.40)
; Calculate Totals
totalAllowances :=
Number(overtimeDayAmount) + Number(legalOvertimeDayAmount) +
Number(nightAmount) + Number(nightOvertimeAmount) +
Number(nightLegalOvertimeAmount) + Number(sundayHolidayAmount) +
Number(sixthDayOvertimeAmount) + Number(nightSixthDayAmount) +
Number(sundayHolidaySixthDayAmount) + Number(nightSundaySixthDayAmount) +
Number(sundayHolidayOvertimeAmount) + Number(sundayHolidayLegalOvertimeAmount) +
Number(nightSundayAmount) + Number(nightSundayOvertimeAmount) +
Number(nightSundayLegalOvertimeAmount)
totalAllowances := Format("{:.2f}", totalAllowances)
grossMonthlyWithBonus := Format("{:.2f}", Number(grossMonthly) + Number(totalAllowances))
; Αποκοπή σε 2 δεκαδικά ψηφία για εμφάνιση
currentGrossDaily := Format("{:.2f}", currentGrossDaily)
grossHourly := Format("{:.4f}", grossHourly)
grossMonthly := Format("{:.2f}", grossMonthly)
; Υπολογισμός ΕΦΚΑ και επιδότησης
employeeContributions := config.insuranceRates
efkaDeduction := Round(Number(grossMonthlyWithBonus) * insuranceRates[insurancePackage], 2)
subsidy := 0
if (isSubsidized) {
subsidy := Round(baseDaily * days * 0.06667, 2)
efkaDeduction := efkaDeduction - subsidy
if (efkaDeduction < 0) {
efkaDeduction := 0
}
}
; Υπολογισμός φορολογικών κρατήσεων
annualTaxable := (Number(grossMonthlyWithBonus) - efkaDeduction) * 14
; Κλιμακωτός φόρος
if (annualTaxable <= 10000) {
annualTax := annualTaxable * 0.09
}
else if (annualTaxable <= 20000) {
annualTax := 900 + (annualTaxable - 10000) * 0.22
}
else if (annualTaxable <= 30000) {
annualTax := 900 + 2200 + (annualTaxable - 20000) * 0.28
}
else if (annualTaxable <= 40000) {
annualTax := 900 + 2200 + 2800 + (annualTaxable - 30000) * 0.36
}
else {
annualTax := 900 + 2200 + 2800 + 3600 + (annualTaxable - 40000) * 0.44
}
; Έκπτωση φόρου βάσει παιδιών
if (children == 0) {
taxDiscount := 777
}
else if (children == 1) {
taxDiscount := 810
}
else if (children == 2) {
taxDiscount := 900
}
else if (children == 3) {
taxDiscount := 1120
}
else if (children == 4) {
taxDiscount := 1340
}
else {
taxDiscount := 1340 + (children - 4) * 220
}
; Τελική προσαρμογή έκπτωσης
if (annualTaxable > 12000) {
taxDiscount := taxDiscount - (annualTaxable - 12000) * 0.02
if (taxDiscount < 0) {
taxDiscount := 0
}
}
; Μηνιαίες κρατήσεις ΦΜΥ
monthlyTaxDeductions := (annualTax - taxDiscount) / 14
; Τελικός καθαρός μισθός
netSalary := Number(grossMonthlyWithBonus) - efkaDeduction - Round(monthlyTaxDeductions, 2)
netSalary := Round(netSalary, 2)
; Prepare Output
output := ""
output .= "----------------------------------`n"
output .= "ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ:`n"
output .= "----------------------------------`n"
output .= "Ημέρες εργασίας: " days "`n"
output .= "Παντρεμένος: " (isMarried ? "Ναι" : "Όχι") "`n"
output .= "Τριετίες: " triennia "`n"
output .= "Κωδικός ενσήμων: " insurancePackage "`n"
output .= "Επιδοτούμενος: " (isSubsidized ? "Ναι" : "Όχι") "`n"
output .= "Μικτό ημερομίσθιο: " currentGrossDaily " €`n"
output .= "Μικτό ωρομίσθιο: " Format("{:.4f}", grossHourly) " €`n"
output .= "Βασικός μηνιαίος μισθός: " grossMonthly " €`n`n"
output .= "----------------------------------`n"
output .= "ΠΡΟΣΑΥΞΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
if (overtimeDayHours > 0)
output .= "Υπερεργασία Ημέρας (" overtimeDayHours " ώρες): " overtimeDayAmount " €`n"
if (legalOvertimeDayHours > 0)
output .= "Νόμιμη Υπερωρία 40% (" legalOvertimeDayHours " ώρες): " legalOvertimeDayAmount " €`n"
if (nightHours > 0)
output .= "Νυχτερινή Απασχόληση (" nightHours " ώρες): " nightAmount " €`n"
if (nightOvertimeHours > 0)
output .= "Νυχτερινή Υπερεργασία (" nightOvertimeHours " ώρες): " nightOvertimeAmount " €`n"
if (nightLegalOvertimeHours > 0)
output .= "Νυχτερινή Νόμιμη 40% (" nightLegalOvertimeHours " ώρες): " nightLegalOvertimeAmount " €`n"
if (sundayHolidayHours > 0)
output .= "Κυριακή/Αργία (" sundayHolidayHours " ώρες): " sundayHolidayAmount " €`n"
if (sixthDayOvertimeHours > 0)
output .= "Υπερωρία 6ης ημέρας (" sixthDayOvertimeHours " ώρες): " sixthDayOvertimeAmount " €`n"
if (nightSixthDayHours > 0)
output .= "Νυχτερινή 6ης ημέρας (" nightSixthDayHours " ώρες): " nightSixthDayAmount " €`n"
if (nightSundayHours > 0)
output .= "Νυχτερινή Κυριακή (" nightSundayHours " ώρες): " nightSundayAmount " €`n"
if (sundayHolidayOvertimeHours > 0)
output .= "Κυριακή/Αργία Υπερεργασία (" sundayHolidayOvertimeHours " ώρες): " sundayHolidayOvertimeAmount " €`n"
if (sundayHolidayLegalOvertimeHours > 0)
output .= "Κυριακή/Αργία Νόμιμη 40% (" sundayHolidayLegalOvertimeHours " ώρες): " sundayHolidayLegalOvertimeAmount " €`n"
if (nightSundayOvertimeHours > 0)
output .= "Νύχτα/Κυριακή Υπερεργασία (" nightSundayOvertimeHours " ώρες): " nightSundayOvertimeAmount " €`n"
if (nightSundayLegalOvertimeHours > 0)
output .= "Νύχτα/Κυριακή Νόμιμη 40% (" nightSundayLegalOvertimeHours " ώρες): " nightSundayLegalOvertimeAmount " €`n"
if (sundayHolidaySixthDayHours > 0)
output .= "Κυριακή/Αργία 6ης ημέρας (" sundayHolidaySixthDayHours " ώρες): " sundayHolidaySixthDayAmount " €`n"
if (nightSundaySixthDayHours > 0)
output .= "Νύχτα/Κυριακή 6ης ημέρας (" nightSundaySixthDayHours " ώρες): " nightSundaySixthDayAmount " €`n"
output .= "Σύνολο Προσαυξήσεων: " totalAllowances " €`n`n"
output .= "----------------------------------`n"
output .= "ΣΥΝΟΛΙΚΑ ΠΡΟΣΑΥΞΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
output .= "Συνολικές προσαυξήσεις: " totalAllowances " €`n"
output .= "Μικτός μηνιαίος μισθός (με προσαυξήσεις): " grossMonthlyWithBonus " €`n`n"
output .= "----------------------------------`n"
output .= "ΑΣΦΑΛΙΣΤΙΚΕΣ ΚΡΑΤΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
if (isSubsidized)
output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
. Format("{:.2f}", Number(grossMonthlyWithBonus) * employeeContributions[insurancePackage]) " €`n"
else
output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
. Format("{:.2f}", Number(grossMonthlyWithBonus) * employeeContributions[insurancePackage]) " €`n`n"
if (isSubsidized) {
output .= "Επιδότηση (Βασικό Ημερομίσθιο " Format("{:.2f}", baseDaily) "€ * " days " ημέρες * 6.667%): " Format("{:.2f}", subsidy) " €`n"
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n`n"
}
output .= "----------------------------------`n"
output .= "ΦΟΡΟΛΟΓΙΚΑ ΣΤΟΙΧΕΙΑ:`n"
output .= "----------------------------------`n"
output .= "Ετήσιο φορολογητέο: " Format("{:.2f}", annualTaxable) " €`n"
output .= "Ετήσιος φόρος: " Format("{:.2f}", annualTax) " €`n"
output .= "Έκπτωση φόρου: " Format("{:.2f}", taxDiscount) " €`n"
output .= "Μηνιαίες κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n`n"
output .= "----------------------------------`n"
output .= "ΤΕΛΙΚΑ ΣΥΝΟΛΑ:`n"
output .= "----------------------------------`n"
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n"
output .= "Καθαρές κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n"
output .= "Καθαρός μηνιαίος μισθός: " Format("{:.2f}", netSalary) " €`n"
; Display Results
OutputSectionCtrl.Value := output
}
; ----------
; ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ ΧΡΙΣΤΟΥΓΕΝΝΩΝ
; ----------
CalculateXmasBonus(*) {
; Input Validation
if !RegExMatch(XmasDailyGrossCtrl.Value, "^\d+(\.\d+)?$") {
MsgBox("Παρακαλώ εισάγετε έγκυρο μικτό ημερομίσθιο (π.χ. 39.3).")
return
}
; Get Values
dailyGross := Number(XmasDailyGrossCtrl.Value)
xmasDays := Number(XmasDaysCtrl.Text)
triennia := Number(XmasTrienniaCtrl.Text)
children := Number(XmasChildrenCtrl.Text)
insurancePackage := Number(XmasInsurancePackageCtrl.Text)
baseDaily := Number(XmasBaseDailyCtrl.Text)
isMarried := XmasMarriedCtrl.Value
isSubsidized := XmasIsSubsidizedCtrl.Value
; Get the coefficient from the map
xmasCoefficient := XmasCoefficients.Has(xmasDays) ? XmasCoefficients[xmasDays] : 0
; Calculate Base Christmas Bonus
currentGrossDaily := dailyGross
; Apply Marriage Bonus (10% of dailyGross)
marriageBonus := 0
if (isMarried) {
marriageBonus := Format("{:.2f}", dailyGross * 0.10)
currentGrossDaily += Number(marriageBonus)
}
; Apply Triennia Bonus (5% of baseDaily per triennia)
trienniaBonus := 0
if (triennia > 0) {
trienniaBonus := Round(Number(baseDaily) * 0.05 * triennia, 2)
currentGrossDaily += trienniaBonus
}
currentGrossDaily := Round(currentGrossDaily, 2)
; Calculate Christmas Bonus (days * coefficient * daily wage)
xmasBonus := Round(currentGrossDaily * xmasCoefficient, 2)
; Calculate Overtime Bonus (divided by 8)
overtimeBonus := Number(XmasOvertimeBonusCtrl.Value) / 8
xmasBonus += overtimeBonus
xmasBonus := Round(xmasBonus, 2)
; Calculate Leave Allowance (4.1666% of Christmas Bonus)
leaveAllowance := Round(xmasBonus * 0.041666, 2)
; Total Gross Christmas Bonus
totalXmasBonus := xmasBonus + leaveAllowance
; Calculate EFKA Deductions
employeeContributions := config.insuranceRates
efkaDeduction := Round(totalXmasBonus * insuranceRates[insurancePackage], 2)
subsidy := 0
if (isSubsidized) {
subsidy := Round(baseDaily * xmasCoefficient * 0.06667, 2)
efkaDeduction := efkaDeduction - subsidy
if (efkaDeduction < 0) {
efkaDeduction := 0
}
}
; Calculate Tax
annualTaxable := (totalXmasBonus - efkaDeduction) * 14
; Progressive Tax Calculation
if (annualTaxable <= 10000) {
annualTax := annualTaxable * 0.09
}
else if (annualTaxable <= 20000) {
annualTax := 900 + (annualTaxable - 10000) * 0.22
}
else if (annualTaxable <= 30000) {
annualTax := 900 + 2200 + (annualTaxable - 20000) * 0.28
}
else if (annualTaxable <= 40000) {
annualTax := 900 + 2200 + 2800 + (annualTaxable - 30000) * 0.36
}
else {
annualTax := 900 + 2200 + 2800 + 3600 + (annualTaxable - 40000) * 0.44
}
; Tax Discount based on children
if (children == 0) {
taxDiscount := 777
}
else if (children == 1) {
taxDiscount := 810
}
else if (children == 2) {
taxDiscount := 900
}
else if (children == 3) {
taxDiscount := 1120
}
else if (children == 4) {
taxDiscount := 1340
}
else {
taxDiscount := 1340 + (children - 4) * 220
}
; Final tax discount adjustment
if (annualTaxable > 12000) {
taxDiscount := taxDiscount - (annualTaxable - 12000) * 0.02
if (taxDiscount < 0) {
taxDiscount := 0
}
}
; Monthly Tax Deductions
monthlyTaxDeductions := (annualTax - taxDiscount) / 14
; Final Net Christmas Bonus
netXmasBonus := totalXmasBonus - efkaDeduction - Round(monthlyTaxDeductions, 2)
netXmasBonus := Round(netXmasBonus, 2)
; Prepare Output
output := ""
output .= "----------------------------------`n"
output .= "ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ ΔΩΡΟΥ ΧΡΙΣΤΟΥΓΕΝΝΩΝ:`n"
output .= "----------------------------------`n"
output .= "Ημέρες απασχόλησης (1/5-31/12): " xmasDays "`n"
output .= "Συντελεστής δώρου: " xmasCoefficient "`n"
output .= "Παντρεμένος: " (isMarried ? "Ναι" : "Όχι") "`n"
output .= "Τριετίες: " triennia "`n"
output .= "Κωδικός ενσήμων: " insurancePackage "`n"
output .= "Επιδοτούμενος: " (isSubsidized ? "Ναι" : "Όχι") "`n"
output .= "Μικτό ημερομίσθιο: " currentGrossDaily " €`n"
output .= "Βασικό ημερομίσθιο: " Format("{:.2f}", baseDaily) " €`n`n"
output .= "----------------------------------`n"
output .= "ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ:`n"
output .= "----------------------------------`n"
output .= "Βασικό δώρο Χριστουγέννων: " Format("{:.2f}", xmasBonus) " €`n"
if (overtimeBonus > 0)
output .= "Προσαύξηση υπερωριών (Μάιος-Νοέμβριος /8): " Format("{:.2f}", overtimeBonus) " €`n"
output .= "Επίδομα αδείας (4.1666%): " Format("{:.2f}", leaveAllowance) " €`n"
output .= "Σύνολο μικτού δώρου: " Format("{:.2f}", totalXmasBonus) " €`n`n"
output .= "----------------------------------`n"
output .= "ΑΣΦΑΛΙΣΤΙΚΕΣ ΚΡΑΤΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
if (isSubsidized) {
output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
. Format("{:.2f}", totalXmasBonus * employeeContributions[insurancePackage]) " €`n"
output .= "Επιδότηση (Βασικό Ημερομίσθιο " Format("{:.2f}", baseDaily) "€ * " xmasCoefficient " * 6.667%): " Format("{:.2f}", subsidy) " €`n"
} else {
output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
. Format("{:.2f}", totalXmasBonus * employeeContributions[insurancePackage]) " €`n"
}
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n`n"
output .= "----------------------------------`n"
output .= "ΦΟΡΟΛΟΓΙΚΑ ΣΤΟΙΧΕΙΑ:`n"
output .= "----------------------------------`n"
output .= "Ετήσιο φορολογητέο: " Format("{:.2f}", annualTaxable) " €`n"
output .= "Ετήσιος φόρος: " Format("{:.2f}", annualTax) " €`n"
output .= "Έκπτωση φόρου: " Format("{:.2f}", taxDiscount) " €`n"
output .= "Μηνιαίες κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n`n"
output .= "----------------------------------`n"
output .= "ΤΕΛΙΚΑ ΣΥΝΟΛΑ:`n"
output .= "----------------------------------`n"
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n"
output .= "Καθαρές κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n"
output .= "Καθαρό δώρο Χριστουγέννων: " Format("{:.2f}", netXmasBonus) " €`n"
; Display Results
XmasOutputSectionCtrl.Value := output
}
; ----------
; ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ ΠΑΣΧΑ
; ----------
CalculateEasterBonus(*) {
; Input Validation
if !RegExMatch(EasterDailyGrossCtrl.Value, "^\d+(\.\d+)?$") {
MsgBox("Παρακαλώ εισάγετε έγκυρο μικτό ημερομίσθιο (π.χ. 39.3).")
return
}
; Get Values
dailyGross := Number(EasterDailyGrossCtrl.Value)
easterDays := Number(EasterDaysCtrl.Text)
triennia := Number(EasterTrienniaCtrl.Text)
children := Number(EasterChildrenCtrl.Text)
insurancePackage := Number(EasterInsurancePackageCtrl.Text)
baseDaily := Number(EasterBaseDailyCtrl.Text)
isMarried := EasterMarriedCtrl.Value
isSubsidized := EasterIsSubsidizedCtrl.Value
; Get the coefficient from the map
easterCoefficient := EasterCoefficients.Has(easterDays) ? EasterCoefficients[easterDays] : 0
; Calculate Base Easter Bonus
currentGrossDaily := dailyGross
; Apply Marriage Bonus (10% of dailyGross)
marriageBonus := 0
if (isMarried) {
marriageBonus := Format("{:.2f}", dailyGross * 0.10)
currentGrossDaily += Number(marriageBonus)
}
; Apply Triennia Bonus (5% of baseDaily per triennia)
trienniaBonus := 0
if (triennia > 0) {
trienniaBonus := Round(Number(baseDaily) * 0.05 * triennia, 2)
currentGrossDaily += trienniaBonus
}
currentGrossDaily := Round(currentGrossDaily, 2)
; Calculate Easter Bonus (days * coefficient * daily wage)
easterBonus := Round(currentGrossDaily * easterCoefficient, 2)
; Calculate Overtime Bonus (divided by 4)
overtimeBonus := Number(EasterOvertimeBonusCtrl.Value) / 4
easterBonus += overtimeBonus
easterBonus := Round(easterBonus, 2)
; Calculate Leave Allowance (4.1666% of Easter Bonus)
leaveAllowance := Round(easterBonus * 0.041666, 2)
; Total Gross Easter Bonus
totalEasterBonus := easterBonus + leaveAllowance
; Calculate EFKA Deductions
employeeContributions := config.insuranceRates
efkaDeduction := Round(totalEasterBonus * insuranceRates[insurancePackage], 2)
subsidy := 0
if (isSubsidized) {
subsidy := Round(baseDaily * easterCoefficient * 0.06667, 2)
efkaDeduction := efkaDeduction - subsidy
if (efkaDeduction < 0) {
	efkaDeduction := 0
}
}
; Calculate Tax (different calculation for Easter bonus)
annualTaxable := (totalEasterBonus - efkaDeduction) * 14 * 2
; Progressive Tax Calculation
if (annualTaxable <= 10000) {
annualTax := annualTaxable * 0.09
}
else if (annualTaxable <= 20000) {
annualTax := 900 + (annualTaxable - 10000) * 0.22
}
else if (annualTaxable <= 30000) {
annualTax := 900 + 2200 + (annualTaxable - 20000) * 0.28
}
else if (annualTaxable <= 40000) {
annualTax := 900 + 2200 + 2800 + (annualTaxable - 30000) * 0.36
}
else {
annualTax := 900 + 2200 + 2800 + 3600 + (annualTaxable - 40000) * 0.44
}
; Tax Discount based on children
if (children == 0) {
taxDiscount := 777
}
else if (children == 1) {
taxDiscount := 810
}
else if (children == 2) {
taxDiscount := 900
}
else if (children == 3) {
taxDiscount := 1120
}
else if (children == 4) {
taxDiscount := 1340
}
else {
taxDiscount := 1340 + (children - 4) * 220
}
; Final tax discount adjustment
if (annualTaxable > 12000) {
taxDiscount := taxDiscount - (annualTaxable - 12000) * 0.02
if (taxDiscount < 0) {
	taxDiscount := 0
}
}
; Monthly Tax Deductions (divided by 2 for Easter bonus)
monthlyTaxDeductions := ((annualTax - taxDiscount) / 14) / 2
; Final Net Easter Bonus
netEasterBonus := totalEasterBonus - efkaDeduction - Round(monthlyTaxDeductions, 2)
netEasterBonus := Round(netEasterBonus, 2)
; Prepare Output
output := ""
output .= "----------------------------------`n"
output .= "ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ ΔΩΡΟΥ ΠΑΣΧΑ:`n"
output .= "----------------------------------`n"
output .= "Ημέρες απασχόλησης (1/1-30/4): " easterDays "`n"
output .= "Συντελεστής δώρου: " easterCoefficient "`n"
output .= "Παντρεμένος: " (isMarried ? "Ναι" : "Όχι") "`n"
output .= "Τριετίες: " triennia "`n"
output .= "Κωδικός ενσήμων: " insurancePackage "`n"
output .= "Επιδοτούμενος: " (isSubsidized ? "Ναι" : "Όχι") "`n"
output .= "Μικτό ημερομίσθιο: " currentGrossDaily " €`n"
output .= "Βασικό ημερομίσθιο: " Format("{:.2f}", baseDaily) " €`n`n"
output .= "----------------------------------`n"
output .= "ΥΠΟΛΟΓΙΣΜΟΣ ΔΩΡΟΥ:`n"
output .= "----------------------------------`n"
output .= "Βασικό δώρο Πάσχα: " Format("{:.2f}", easterBonus) " €`n"
if (overtimeBonus > 0)
output .= "Προσαύξηση υπερωριών (Ιανουάριος-Απρίλιος /4): " Format("{:.2f}", overtimeBonus) " €`n"
output .= "Επίδομα αδείας (4.1666%): " Format("{:.2f}", leaveAllowance) " €`n"
output .= "Σύνολο μικτού δώρου: " Format("{:.2f}", totalEasterBonus) " €`n`n"
output .= "----------------------------------`n"
output .= "ΑΣΦΑΛΙΣΤΙΚΕΣ ΚΡΑΤΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
if (isSubsidized) {
	output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
	. Format("{:.2f}", totalEasterBonus * employeeContributions[insurancePackage]) " €`n"
	output .= "Επιδότηση (Βασικό Ημερομίσθιο " Format("{:.2f}", baseDaily) "€ * " easterCoefficient " * 6.667%): " Format("{:.2f}", subsidy) " €`n"
} else {
	output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
	. Format("{:.2f}", totalEasterBonus * employeeContributions[insurancePackage]) " €`n"
}
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n`n"
output .= "----------------------------------`n"
output .= "ΦΟΡΟΛΟΓΙΚΑ ΣΤΟΙΧΕΙΑ:`n"
output .= "----------------------------------`n"
output .= "Ετήσιο φορολογητέο: " Format("{:.2f}", annualTaxable) " €`n"
output .= "Ετήσιος φόρος: " Format("{:.2f}", annualTax) " €`n"
output .= "Έκπτωση φόρου: " Format("{:.2f}", taxDiscount) " €`n"
output .= "Μηνιαίες κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n`n"
output .= "----------------------------------`n"
output .= "ΤΕΛΙΚΑ ΣΥΝΟΛΑ:`n"
output .= "----------------------------------`n"
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n"
output .= "Καθαρές κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n"
output .= "Καθαρό δώρο Πάσχα: " Format("{:.2f}", netEasterBonus) " €`n"
; Display Results
EasterOutputSectionCtrl.Value := output
}
; ----------
; ΥΠΟΛΟΓΙΣΜΟΣ ΕΠΙΔΟΜΑΤΟΣ ΑΔΕΙΑΣ
; ----------
CalculateLeaveAllowance(*) {
; Input Validation
if !RegExMatch(LeaveDailyGrossCtrl.Value, "^\d+(\.\d+)?$") {
	MsgBox("Παρακαλώ εισάγετε έγκυρο μικτό ημερομίσθιο (π.χ. 39.3).")
	return
}
; Get Values
dailyGross := Number(LeaveDailyGrossCtrl.Value)
leaveDays := Number(LeaveDaysCtrl.Text)
triennia := Number(LeaveTrienniaCtrl.Text)
children := Number(LeaveChildrenCtrl.Text)
insurancePackage := Number(LeaveInsurancePackageCtrl.Text)
baseDaily := Number(LeaveBaseDailyCtrl.Text)
isMarried := LeaveMarriedCtrl.Value
isSubsidized := LeaveIsSubsidizedCtrl.Value
; Calculate Base Leave Allowance
currentGrossDaily := dailyGross
; Apply Marriage Bonus (10% of dailyGross)
marriageBonus := 0
if (isMarried) {
	marriageBonus := Format("{:.2f}", dailyGross * 0.10)
	currentGrossDaily += Number(marriageBonus)
}
; Apply Triennia Bonus (5% of baseDaily per triennia)
trienniaBonus := 0
if (triennia > 0) {
	trienniaBonus := Round(Number(baseDaily) * 0.05 * triennia, 2)
	currentGrossDaily += trienniaBonus
}
currentGrossDaily := Round(currentGrossDaily, 2)
; Calculate Leave Allowance (days * daily wage)
leaveBonus := Round(currentGrossDaily * leaveDays, 2)
; Total Gross Leave Allowance
totalLeaveBonus := leaveBonus
; Calculate EFKA Deductions
employeeContributions := config.insuranceRates
efkaDeduction := Round(totalLeaveBonus * insuranceRates[insurancePackage], 2)
subsidy := 0
if (isSubsidized) {
	subsidy := Round(baseDaily * leaveDays * 0.06667, 2)
	efkaDeduction := efkaDeduction - subsidy
	if (efkaDeduction < 0) {
		efkaDeduction := 0
	}
}
; Calculate Tax (different calculation for Leave allowance)
annualTaxable := (totalLeaveBonus - efkaDeduction) * 14 * 2
; Progressive Tax Calculation
if (annualTaxable <= 10000) {
	annualTax := annualTaxable * 0.09
}
else if (annualTaxable <= 20000) {
	annualTax := 900 + (annualTaxable - 10000) * 0.22
}
else if (annualTaxable <= 30000) {
	annualTax := 900 + 2200 + (annualTaxable - 20000) * 0.28
}
else if (annualTaxable <= 40000) {
	annualTax := 900 + 2200 + 2800 + (annualTaxable - 30000) * 0.36
}
else {
	annualTax := 900 + 2200 + 2800 + 3600 + (annualTaxable - 40000) * 0.44
}
; Tax Discount based on children
if (children == 0) {
	taxDiscount := 777
}
else if (children == 1) {
	taxDiscount := 810
}
else if (children == 2) {
	taxDiscount := 900
}
else if (children == 3) {
	taxDiscount := 1120
}
else if (children == 4) {
	taxDiscount := 1340
}
else {
	taxDiscount := 1340 + (children - 4) * 220
}
; Final tax discount adjustment
if (annualTaxable > 12000) {
	taxDiscount := taxDiscount - (annualTaxable - 12000) * 0.02
	if (taxDiscount < 0) {
		taxDiscount := 0
	}
}
; Monthly Tax Deductions (divided by 2 for Leave allowance)
monthlyTaxDeductions := ((annualTax - taxDiscount) / 14) / 2
; Final Net Leave Allowance
netLeaveBonus := totalLeaveBonus - efkaDeduction - Round(monthlyTaxDeductions, 2)
netLeaveBonus := Round(netLeaveBonus, 2)
; Prepare Output
output := ""
output .= "----------------------------------`n"
output .= "ΒΑΣΙΚΑ ΣΤΟΙΧΕΙΑ ΕΠΙΔΟΜΑΤΟΣ ΑΔΕΙΑΣ:`n"
output .= "----------------------------------`n"
output .= "Ημέρες απασχόλησης: " leaveDays "`n"
output .= "Παντρεμένος: " (isMarried ? "Ναι" : "Όχι") "`n"
output .= "Τριετίες: " triennia "`n"
output .= "Κωδικός ενσήμων: " insurancePackage "`n"
output .= "Επιδοτούμενος: " (isSubsidized ? "Ναι" : "Όχι") "`n"
output .= "Μικτό ημερομίσθιο: " currentGrossDaily " €`n"
output .= "Βασικό ημερομίσθιο: " Format("{:.2f}", baseDaily) " €`n`n"
output .= "----------------------------------`n"
output .= "ΥΠΟΛΟΓΙΣΜΟΣ ΕΠΙΔΟΜΑΤΟΣ:`n"
output .= "----------------------------------`n"
output .= "Σύνολο μικτού επιδόματος: " Format("{:.2f}", totalLeaveBonus) " €`n`n"
output .= "----------------------------------`n"
output .= "ΑΣΦΑΛΙΣΤΙΚΕΣ ΚΡΑΤΗΣΕΙΣ:`n"
output .= "----------------------------------`n"
if (isSubsidized) {
	output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
	. Format("{:.2f}", totalLeaveBonus * employeeContributions[insurancePackage]) " €`n"
	output .= "Επιδότηση (Βασικό Ημερομίσθιο " Format("{:.2f}", baseDaily) "€ * " leaveDays " * 6.667%): " Format("{:.2f}", subsidy) " €`n"
} else {
	output .= "Εισφορές εργαζομένου (" Format("{:.2f}", employeeContributions[insurancePackage]*100) "%): "
	. Format("{:.2f}", totalLeaveBonus * employeeContributions[insurancePackage]) " €`n"
}
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n`n"
output .= "----------------------------------`n"
output .= "ΦΟΡΟΛΟΓΙΚΑ ΣΤΟΙΧΕΙΑ:`n"
output .= "----------------------------------`n"
output .= "Ετήσιο φορολογητέο: " Format("{:.2f}", annualTaxable) " €`n"
output .= "Ετήσιος φόρος: " Format("{:.2f}", annualTax) " €`n"
output .= "Έκπτωση φόρου: " Format("{:.2f}", taxDiscount) " €`n"
output .= "Μηνιαίες κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n`n"
output .= "----------------------------------`n"
output .= "ΤΕΛΙΚΑ ΣΥΝΟΛΑ:`n"
output .= "----------------------------------`n"
output .= "Καθαρές κρατήσεις ΕΦΚΑ: " Format("{:.2f}", efkaDeduction) " €`n"
output .= "Καθαρές κρατήσεις ΦΜΥ: " Format("{:.2f}", monthlyTaxDeductions) " €`n"
output .= "Καθαρό επίδομα αδείας: " Format("{:.2f}", netLeaveBonus) " €`n"
; Display Results
LeaveOutputSectionCtrl.Value := output
}
; ----------
; ΑΠΟΘΗΚΕΥΣΗ FUNCTION
; ----------
SaveToFile(fileType, content) {
if (content == "") {
	MsgBox("Δεν υπάρχουν δεδομένα για αποθήκευση.", "Προσοχή", "Icon!")
	return
}
if !DirExist("Μισθοδοσία") {
	DirCreate("Μισθοδοσία")
}
timeStr := FormatTime(, "yyyy_MM_dd_HHmmss")
fileName := "Μισθοδοσία\" . fileType . "_" . timeStr . ".txt"
try { ; Προσπάθεια δημιουργίας αρχείου αν δεν υπάρχει
	FileAppend(content "`n`n", fileName, "UTF-8")
	MsgBox("Τα στοιχεία αποθηκεύτηκαν στο αρχείο:`n" fileName, "Αποθήκευση", "Iconi")
} catch Error as e {
	MsgBox("Σφάλμα κατά την αποθήκευση:`n" . e.Message, "Σφάλμα", "Icon!")
}
}
; ----------
; SHOW INFO FUNCTION
; ----------
ShowInfo(*) {
infoText := ""
infoText .= "Ergatocalc`n"
infoText .= "Έκδοση: v1.0`n"
infoText .= "Δημιουργός: Tasos`n"
infoText .= "Ημερομηνία Έκδοσης: 23/05/2025`n"
infoText .= "`n"
infoText .= "Email: maxiths1984@gmail.com`n"
infoText .= "`n"
infoText .= "© 2025 Όλα τα δικαιώματα διατηρούνται"
MsgBox(infoText, "Πληροφορίες Προγράμματος", "Iconi")
}
}