import SwiftUI

// MARK: - Manpower Role Model
struct ManpowerRole: Identifiable, Codable {
    let id: UUID
    var title: String
    var isChecked: Bool

    init(id: UUID = UUID(), title: String, isChecked: Bool = false) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - Condition Model
struct Condition: Identifiable, Equatable {
    static func == (lhs: borrowing Condition, rhs: borrowing Condition) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID()
    let name: String
    let description: String
    let procedures: String
    var manpowerRoles: [ManpowerRole]
}

private let nicuTeamRoles: [ManpowerRole] = [
    ManpowerRole(title: "Neonatologist / Team Leader"),
    ManpowerRole(title: "Neonatal Doctor"),
    ManpowerRole(title: "Nurse – Lines & Fluids"),
    ManpowerRole(title: "Nurse – Monitoring & Documentation"),
    ManpowerRole(title: "Respiratory Therapist"),
]

let defaultConditions: [Condition] = [
    Condition(
        name: "Gastroschisis / Omphalocele",
        description: "Cover sac/bowel, side positioning, long line (avoid umbilical), broad-spectrum antibiotics.",
        procedures: """
        GASTROSCHISIS / OMPHALOCELE

        NICU Management
        • Respi/CVS: Ventilator settings, CXR/AXR, monitor for pulmonary hypoplasia/PPHN, hypovolemia
        • Fluids/GI: TF 60 ml/kg/day, NBM + early TPN, NG tube for decompression, strict I/O + fluid monitoring
        • Lines: Long line insertion (avoid umbilical lines)
        • ID: Broad-spectrum antibiotics
        • Others: Cover sac/bowel, side positioning, monitor bowel perfusion & compartment syndrome, discuss operative plan

        Investigations
        • Examine for dysmorphism
        • Pre-op bloods: FBC, PT/PTT, GXM
        • Associated abnormalities:
           - Karyotype/CMA
           - Cranial US
           - 2DE
           - US spine/abdomen
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "Surgeons")]
    ),
    Condition(
        name: "Hydrops Fetalis",
        description: "HFOV/iNO PRN, manage severe anemia, slow transfusion, assess severity + dysmorphism.",
        procedures: """
        HYDROPS FETALIS

        NICU Management
        • Respi/CVS: HFOV/iNO PRN, CXR/AXR ± US, monitor PPHN/systemic hypotension
        • Fluids/GI: TF 60 ml/kg/day, NBM, strict I/O + hypocount monitoring
        • Lines: UVC/UAC
        • Haem: Manage severe anemia, slow transfusion/partial exchange
        • Others: Assess severity of hydrops + dysmorphism

        Investigations
        • FBC, PBF, Retic
        • LFT, DCT, LDH
        • PT/PTT, GXM
        • Maternal Kleihauer
        • Genetics referral/DNA extraction
        • IUI workup
        • Lactate/ammonia/IEM screen
        """,
        manpowerRoles: nicuTeamRoles
    ),
    Condition(
        name: "Congenital Diaphragmatic Hernia",
        description: "Ventilator, surfactant PRN, Replogle suction, avoid bowel distension, echo.",
        procedures: """
        CONGENITAL DIAPHRAGMATIC HERNIA

        NICU Management
        • Respi/CVS: Ventilator settings, CXR/AXR, surfactant PRN, monitor PPHN/pneumothorax, iNO/HFOV, echo
        • Fluids/GI: TF 60 ml/kg/day, NBM + early TPN, Replogle suction, avoid bowel gaseous distension
        • Lines: UVC/UAC
        • Others: Morphine sedation PRN, discuss operative timing with surgeons

        Investigations
        • Examine for dysmorphism
        • Karyotype/CMA
        • Cranial US
        • 2DE
        • US spine/abdomen
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "Surgeons")]
    ),
    Condition(
        name: "Myelomeningocele",
        description: "Neuro assessment, CrUS, monitor OFC, antibiotics if ruptured, discuss surgery.",
        procedures: """
        MYELOMENINGOCELE

        NICU Management
        • Respi/CVS: Respiratory support PRN
        • Fluids/GI: TF 60 ml/kg/day, NBM ± early TPN
        • Neuro: Neurological assessment, assess bladder/bowel involvement, CrUS, monitor OFC
        • Lines: Long line insertion PRN
        • ID: Broad-spectrum antibiotics if ruptured, monitor for meningitis/sepsis
        • Others: Assess sac integrity, CSF leak/exposed nerves, discuss surgery

        Investigations
        • Neurological examination
        • Examine for dysmorphism
        • Pre-op bloods: FBC, PT/PTT, GXM
        • Karyotype/CMA
        • Cranial US
        • 2DE
        • US spine/abdomen
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "Neurosurgeons")]
    ),
    Condition(
        name: "Twin-to-Twin Transfusion Syndrome",
        description: "Donor/recipient twin management, drains for effusions, PCT transfusion PRN.",
        procedures: """
        TWIN-TO-TWIN TRANSFUSION SYNDROME

        NICU Management
        • Respi/CVS: Ventilator settings, CXR/AXR, surfactant donor twin, monitor PPHN, iNO/HFOV, echo
        • Fluids/GI: NBM + fluid management
        • Lines: UVC/UAC, chest/abdominal drains if significant effusions
        • Haem: Donor twin may require PCT transfusion, recipient twin may develop polycythemia/NNJ

        Investigations
        • US chest
        • US abdomen
        • Assess degree of effusions
        • Fetal echo review
        """,
        manpowerRoles: nicuTeamRoles
    ),
    Condition(
        name: "Congenital Heart Disease",
        description: "Echo, maintain BP, PGE infusion, screen for syndromic features.",
        procedures: """
        CONGENITAL HEART DISEASE

        NICU Management
        • Respi/CVS: CPAP/intubation PRN, CXR, echo, maintain BP, monitor lactate, PGE infusion
        • Fluids/GI: NBM + fluid management
        • Lines: UVC/UAC
        • Others: Screen for syndromic features, discuss intervention timing with cardiology

        PGE Guide
        • Dilution: (Weight × 30) mcg in 50ml
        • 1 ml/hr = 0.01 mcg/kg/min
        • Usual rate: 0.01–0.1 mcg/kg/min

        Investigations
        • Karyotype/CMA
        • US spine/abdomen/head
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "Cardiology")]
    ),
    Condition(
        name: "Anticipated Difficult Airway",
        description: "Airway imaging, maintain BP, discuss definitive surgical management.",
        procedures: """
        ANTICIPATED DIFFICULT AIRWAY

        NICU Management
        • Respi/CVS: Ventilator settings, CXR, maintain BP
        • Fluids/GI: NBM + fluid management
        • Lines: UVC/UAC
        • Others: Imaging for airway anatomy, discuss definitive surgical management

        Investigations
        • Pre-op bloods: FBC, PT/PTT, GXM
        • Karyotype/CMA
        • 2DE
        • US spine/abdomen
        • CT neck/chest
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "ENT / Surgeons")]
    ),
    Condition(
        name: "Hypoxic Ischaemic Encephalopathy (HIE)",
        description: "Therapeutic hypothermia if ≥ 36 wk with moderate–severe HIE, within 6 h. Score with the Thompson calculator.",
        procedures: """
        HYPOXIC ISCHAEMIC ENCEPHALOPATHY (HIE)

        Therapeutic Hypothermia (TH) — Eligibility
        • ≥ 36 weeks' gestation AND moderate-to-severe HIE
        • Start within 6 h of life · core temperature 33–34°C for 72 h
        • Rewarm slowly to 36.5°C (0.5°C/h) · avoid accidental hyperthermia
        • Manage in a centre with expertise, intensive care support, EEG/aEEG and longitudinal follow-up

        Therapeutic Hypothermia — Management
        • Respi/CVS: Ventilator/CPAP PRN, maintain normotension, monitor lactate
        • Fluids/GI: NBM + early TPN; early glucose infusion guided by serial glucose
        • Neuro: Sedation/anticonvulsants as needed; EEG/aEEG for seizure monitoring
        • Bloods: FBC, glucose (early & regular), lactate, renal panel, LFT, coagulation profile
        • Others: Treat seizures, avoid hyperthermia, update parents, plan follow-up imaging

        Investigations
        • Cranial ultrasound
        • MRI brain (after stabilisation, per unit protocol)
        • EEG / amplitude-integrated EEG
        • IEM markers: lactate, ammonia, IEM screen if indicated
        """,
        manpowerRoles: nicuTeamRoles + [ManpowerRole(title: "Neurology")]
    ),
    Condition(
        name: "VLBW / GA <33 Weeks",
        description: "SpO₂ 90–95%, surfactant/MIST, starter TPN, cranial US, NeoXM.",
        procedures: """
        VLBW / GA <33 WEEKS

        NICU Management
        • Respi/CVS: Target SpO2 90–95%, respiratory support PRN, surfactant/MIST if indicated
        • Fluids/GI: TF 60 ml/kg/day (80 if BW <1kg), starter TPN, feeds as per protocol, strict I/O
        • Neuro: Cranial US, consider indomethacin prophylaxis if high IVH risk
        • Lines: UVC/UAC PRN
        • ID: Antibiotics PRN, consider ampicillin if meconium-stained liquor

        Investigations
        • Blood investigations
        • Blood cultures
        • NeoXM
        • SB at 13 & 25 HOL
        """,
        manpowerRoles: nicuTeamRoles
    ),
]

// MARK: - Conditions List View
// NOTE: This renders inline inside the parent screen's ScrollView
// (NeonatalEmergenciesHomeView). It deliberately does NOT own a
// NavigationView or a List — a List is itself a scroll container, and
// nesting one inside another ScrollView gives it a zero/collapsed height
// proposal, which is what caused the clipped, squished-looking conditions
// section. Plain VStack rows flow naturally in the single parent scroll.
struct CommonConditionsView: View {
    @Binding var weight: String
    @EnvironmentObject private var syncService: ConditionSyncService
    @State private var conditions: [Condition] = CommonConditionsView.initialConditions()
    @State private var deletedBuiltIns: Set<String> = []
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var isManaging = false            // shows a trash button on every row
    @State private var pendingDelete: Condition?     // drives the confirmation dialog
    @FocusState private var searchFocused: Bool

    static let deletedBuiltInsKey = "kkhs2.deletedBuiltInConditions"

    /// Bundled conditions minus the ones the team has deleted on this
    /// device (deletions of built-ins are local-only; cloud rows are
    /// deleted for everyone).
    static func initialConditions() -> [Condition] {
        let deleted = UserDefaults.standard.stringArray(forKey: deletedBuiltInsKey) ?? []
        return defaultConditions.filter { !deleted.contains($0.name) }
    }

    private var builtInNames: Set<String> { Set(defaultConditions.map(\.name)) }
    private var cloudCustomNames: Set<String> { Set(syncService.customConditions.map(\.name)) }
    private func isCustom(_ name: String) -> Bool { cloudCustomNames.contains(name) }

    private func saveDeletedBuiltIns() {
        UserDefaults.standard.set(Array(deletedBuiltIns).sorted(), forKey: CommonConditionsView.deletedBuiltInsKey)
    }

    /// Pulls the cloud list into the local one: appends new/updated custom
    /// conditions, drops custom rows deleted elsewhere, and hides built-ins
    /// that have been replaced by a cloud row of the same name. Only runs
    /// the removal pass on a successful fetch so a network failure never
    /// wipes locally-visible rows.
    private func reconcileWithCloud() {
        let cloud = syncService.customConditions
        guard syncService.lastError == nil else { return }
        let cloudNames = Set(cloud.map(\.name))

        // Custom rows that no longer exist in the cloud (deleted on another device)
        conditions.removeAll { row in
            !builtInNames.contains(row.name) && !cloudNames.contains(row.name)
        }
        // Built-ins shadowed by a cloud row with the same name
        conditions.removeAll { row in
            builtInNames.contains(row.name) && cloudNames.contains(row.name)
        }
        // Cloud rows not present locally yet
        for row in cloud where !conditions.contains(where: { $0.name == row.name }) {
            conditions.append(Condition(
                name: row.name,
                description: row.description,
                procedures: row.procedures,
                manpowerRoles: row.roles.map { ManpowerRole(title: $0) }))
        }
    }

    private func deleteCondition(_ condition: Condition) {
        Haptics.mediumTap()
        withAnimation { conditions.removeAll { $0.id == condition.id } }
        if isCustom(condition.name) {
            // Cloud row: delete for everyone. If the cloud refuses (or removes
            // nothing), pull the list again so the row comes back instead of
            // silently "deleting" locally and reappearing on next launch.
            Task {
                let ok = await syncService.deleteCondition(named: condition.name)
                if !ok {
                    let message = syncService.lastError
                    await refreshFromCloud()
                    syncService.lastError = message
                }
            }
        } else {
            // Built-in: hide locally and remember across launches.
            deletedBuiltIns.insert(condition.name)
            saveDeletedBuiltIns()
        }
    }

    private var deleteDialogTitle: String {
        "Delete “\(pendingDelete?.name ?? "")”?"
    }
    private var deleteDialogMessage: String {
        guard let c = pendingDelete else { return "" }
        return isCustom(c.name)
            ? "This removes it for everyone on the team."
            : "This hides the built-in condition on this device."
    }

    var filteredConditions: [Condition] {
        searchText.isEmpty ? conditions : conditions.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Search field
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Search conditions…", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                    .focused($searchFocused)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button {
                        Haptics.checklistTap()
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous).stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1))

            // ── Cloud sync status ──────────────────────────────────────
            if syncService.isSyncing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Syncing with cloud…")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let syncError = syncService.lastError {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.caption)
                        .foregroundColor(AppTheme.danger)
                    Text(syncError)
                        .font(.caption)
                        .foregroundColor(AppTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {
                        Haptics.checklistTap()
                        syncService.lastError = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.bold())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
            }

            if filteredConditions.isEmpty {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(searchText.isEmpty ? "No conditions yet." : "No conditions match “\(searchText)”.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xl)
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(filteredConditions) { condition in
                        if let idx = conditions.firstIndex(where: { $0.id == condition.id }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                NavigationLink {
                                    ConditionDetailView(condition: $conditions[idx], weight: $weight)
                                } label: {
                                    ConditionRowView(condition: condition)
                                        .padding(AppTheme.Spacing.md)
                                        .background(AppTheme.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(AppTheme.accentMuted.opacity(0.35), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingDelete = condition
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // Visible, tappable delete — long-press alone was too hidden.
                                if isManaging {
                                    Button {
                                        Haptics.checklistTap()
                                        pendingDelete = condition
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(AppTheme.danger)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Delete \(condition.name)")
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
            }

            HStack {
                Button {
                    Haptics.checklistTap()
                    showingAddSheet = true
                } label: {
                    Label("Add Condition", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.accent)
                }
                Spacer()
                Button {
                    Haptics.checklistTap()
                    withAnimation(.easeInOut(duration: 0.2)) { isManaging.toggle() }
                } label: {
                    Label(isManaging ? "Done" : "Delete…", systemImage: isManaging ? "checkmark" : "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isManaging ? AppTheme.accent : AppTheme.danger)
                }
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let c = pendingDelete { deleteCondition(c) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(deleteDialogMessage)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddProcedureSheet(conditions: $conditions)
        }
        .onAppear {
            deletedBuiltIns = Set(UserDefaults.standard.stringArray(forKey: Self.deletedBuiltInsKey) ?? [])
            Task { await refreshFromCloud() }
        }
    }

    private func refreshFromCloud() async {
        await syncService.loadConditions()
        reconcileWithCloud()
    }
}

// MARK: - Condition Row
struct ConditionRowView: View {
    let condition: Condition

    var checkedCount: Int { condition.manpowerRoles.filter(\.isChecked).count }
    var totalCount: Int { condition.manpowerRoles.count }
    var progress: Double { totalCount > 0 ? Double(checkedCount) / Double(totalCount) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(condition.name)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            Text(condition.description)
                .font(.subheadline)
                .foregroundColor(AppTheme.accent)
                .lineLimit(2)
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Text("\(checkedCount)/\(totalCount) roles assigned")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                if checkedCount == totalCount && totalCount > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.success)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Condition Detail View
struct ConditionDetailView: View {
    @Binding var condition: Condition
    @Binding var weight: String

    var weightKg: Double { Double(weight) ?? 0 }
    var fluidBolus: Double { weightKg * 10 }
    var epiDose: Double { weightKg * 0.1 }
    var glucoseDose: Double { weightKg * 2.5 }
    var hasProtocolText: Bool { !condition.procedures.isEmpty && condition.procedures != "nil" }
    var hasProtocolContent: Bool { hasProtocolText || !protocolImages(for: condition.name).isEmpty }
    var assignedCount: Int { condition.manpowerRoles.filter(\.isChecked).count }
    var totalCount: Int { condition.manpowerRoles.count }
    var progress: Double { totalCount > 0 ? Double(assignedCount) / Double(totalCount) : 0 }

    /// Red → orange → green as roles get assigned; solid green at 100%.
    var progressColor: Color {
        if progress >= 1 { return AppTheme.success }
        if progress <= 0 { return AppTheme.danger }
        return AppTheme.warning
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text(condition.description)
                            .font(.body)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .sectionCard()

                    // Manpower checklist
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Manpower Required", systemImage: "person.3.fill")
                                .font(.title3.bold())
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            PillBadge(
                                text: "\(assignedCount)/\(totalCount)",
                                color: progressColor
                            )
                        }

                        // Progress bar — red → orange → green gradient,
                        // clamped to the filled fraction so it reads as a
                        // “getting safer” gauge.
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppTheme.accentMuted.opacity(0.3))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.danger, AppTheme.warning, AppTheme.success],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .mask(
                                        RoundedRectangle(cornerRadius: 6)
                                            .frame(
                                                width: totalCount > 0
                                                    ? geo.size.width * CGFloat(assignedCount) / CGFloat(totalCount)
                                                    : 0,
                                                height: 8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    )
                                    .animation(.easeInOut, value: assignedCount)
                            }
                        }
                        .frame(height: 8)

                        ForEach($condition.manpowerRoles) { $role in
                            HStack(spacing: 12) {
                                Button {
                                    Haptics.checklistTap()
                                    role.isChecked.toggle()
                                } label: {
                                    Image(systemName: role.isChecked ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(role.isChecked ? AppTheme.success : AppTheme.accentMuted)
                                        .animation(.spring(response: 0.3), value: role.isChecked)
                                }
                                .buttonStyle(.plain)

                                Text(role.title)
                                    .font(.body)
                                    .strikethrough(role.isChecked, color: AppTheme.textSecondary)
                                    .foregroundColor(role.isChecked ? AppTheme.textSecondary : AppTheme.textPrimary)

                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(role.isChecked ? AppTheme.success.opacity(0.07) : AppTheme.surface)
                            .cornerRadius(12)
                            .animation(.easeInOut(duration: 0.2), value: role.isChecked)
                        }

                        if assignedCount > 0 {
                            Button {
                                Haptics.mediumTap()
                                for i in condition.manpowerRoles.indices {
                                    condition.manpowerRoles[i].isChecked = false
                                }
                            } label: {
                                Label("Reset Checklist", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.danger)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .sectionCard()

                    // Resuscitation drugs (weight-based) — second priority after manpower
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Resuscitation Drugs", systemImage: "pills.fill")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        DrugsSectionView(weightKg: weightKg)
                    }
                    .sectionCard()

                    // Thompson HIE severity score — only shown on the HIE page
                    if condition.name.lowercased().contains("hypoxic") || condition.name.lowercased().contains("hie") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Thompson HIE Score", systemImage: "brain.head.profile")
                                .font(.title3.bold())
                                .foregroundColor(AppTheme.textPrimary)
                            ThompsonScoreSectionView()
                        }
                        .sectionCard()
                    }

                    // NICU protocol — reference material, kept last
                    if hasProtocolContent {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("NICU Protocol", systemImage: "doc.text.fill")
                                .font(.title3.bold())
                                .foregroundColor(AppTheme.textPrimary)

                            ForEach(protocolImages(for: condition.name)) { image in
                                ProtocolImageCard(image: image)
                            }

                            if hasProtocolText {
                                Text(condition.procedures)
                                    .font(.body)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .sectionCard()
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }
        }
        .navigationTitle(condition.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Add Procedure Sheet
private enum AddConditionField: Hashable { case name, description, procedures, role }

struct AddProcedureSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var syncService: ConditionSyncService
    @Binding var conditions: [Condition]

    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newProcedures = ""
    @State private var newRoles: [ManpowerRole] = []
    @State private var newRoleText = ""
    @FocusState private var focusedField: AddConditionField?

    private var canSave: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                        // ── Details ──────────────────────────────────
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            FormSectionLabel(title: "Details", systemImage: "doc.text.fill")

                            LabeledField(title: "Condition Name") {
                                TextField("e.g. Necrotising Enterocolitis", text: $newName)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .description }
                            }

                            LabeledField(title: "Short Summary", subtitle: "Shown on the condition's row in the list") {
                                PlaceholderTextEditor(
                                    text: $newDescription,
                                    placeholder: "One line the on-call team can scan at a glance",
                                    minHeight: 64
                                )
                                .focused($focusedField, equals: .description)
                            }

                            LabeledField(title: "NICU Protocol", subtitle: "Full management plan & investigations") {
                                PlaceholderTextEditor(
                                    text: $newProcedures,
                                    placeholder: "Respi/CVS, Fluids/GI, Lines, ID, Investigations…",
                                    minHeight: 160
                                )
                                .focused($focusedField, equals: .procedures)
                            }
                        }
                        .appCard()

                        // ── Manpower ─────────────────────────────────
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            FormSectionLabel(title: "Manpower Roles", systemImage: "person.3.fill")

                            if newRoles.isEmpty {
                                Text("No roles added yet. Roles you add appear here as a checklist on the condition's page.")
                                    .font(.footnote)
                                    .foregroundColor(AppTheme.textSecondary)
                            } else {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach(newRoles) { role in
                                        HStack(spacing: AppTheme.Spacing.sm) {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(AppTheme.accent)
                                                .frame(width: 20)
                                            Text(role.title)
                                                .font(.subheadline)
                                                .foregroundColor(AppTheme.textPrimary)
                                            Spacer()
                                            Button {
                                                Haptics.checklistTap()
                                                newRoles.removeAll { $0.id == role.id }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(AppTheme.danger)
                                            }
                                        }
                                        .padding(AppTheme.Spacing.sm)
                                        .background(AppTheme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
                                    }
                                }
                            }

                            HStack(spacing: AppTheme.Spacing.sm) {
                                TextField("Add role (e.g. Nurse – IV Access)", text: $newRoleText)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .focused($focusedField, equals: .role)
                                    .submitLabel(.done)
                                    .onSubmit(addRole)
                                    .padding(AppTheme.Spacing.sm)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))

                                Button(action: addRole) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(newRoleText.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.accent.opacity(0.4) : AppTheme.accent)
                                }
                                .disabled(newRoleText.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .appCard()

                        Spacer(minLength: AppTheme.Spacing.xl)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationTitle("Add Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Haptics.notify(.success)
                        let name = newName.trimmingCharacters(in: .whitespaces)
                        let roles = newRoles.map(\.title)
                        // Local-first: the row appears immediately, then is
                        // pushed to Supabase so every device gets it.
                        conditions.append(Condition(
                            name: name,
                            description: newDescription,
                            procedures: newProcedures,
                            manpowerRoles: newRoles))
                        dismiss()
                        Task {
                            let stored = await syncService.addCondition(
                                name: name,
                                description: newDescription,
                                procedures: newProcedures,
                                roles: roles)
                            if stored == nil {
                                // Cloud write failed — roll back the local row
                                // so the list doesn't silently diverge.
                                Haptics.notify(.error)
                                conditions.removeAll { $0.name == name }
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave || syncService.isSyncing)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func addRole() {
        let t = newRoleText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        Haptics.checklistTap()
        newRoles.append(ManpowerRole(title: t))
        newRoleText = ""
    }
}

// MARK: - Shared form-building blocks

private struct FormSectionLabel: View {
    let title: String
    let systemImage: String
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundColor(AppTheme.accent)
            .textCase(.uppercase)
            .kerning(0.4)
    }
}

private struct LabeledField<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundColor(AppTheme.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary.opacity(0.8))
            }
            content
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))
        }
    }
}

/// A TextEditor with a real placeholder and explicit, theme-aware colors —
/// the plain TextEditor + Form combination is what made this screen hard
/// to read (system default text/background colors fighting the app's
/// custom palette). Everything here is colored explicitly instead.
private struct PlaceholderTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: $text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
    }
}
