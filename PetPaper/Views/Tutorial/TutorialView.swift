import SwiftUI

struct TutorialView: View {
    @Environment(AppSession.self) private var session
    @Environment(SubscriptionManager.self) private var subscriptions
    @State private var step = 0
    @State private var template: TemplateKind = .pastel
    @State private var petID = PetCharacter.catalog[0].id
    @State private var demoStore = EditorStore(template: .pastel, petID: PetCharacter.catalog[0].id)

    var body: some View {
        @Bindable var subscriptions = subscriptions
        VStack(spacing: 0) {
            HStack {
                Button(String(localized: "tutorial.skip")) {
                    AppHaptics.light()
                    session.skipTutorial()
                }
                .foregroundStyle(AppTheme.muted)
                Spacer()
                Text("\(step + 1)/5")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            TabView(selection: $step) {
                welcomePage.tag(0)
                templatePage.tag(1)
                petPage.tag(2)
                followPage.tag(3)
                exportPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 12) {
                if step > 0 {
                    Button(String(localized: "tutorial.back")) {
                        withAnimation { step -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.ink)
                }
                Button(step == 4 ? String(localized: "tutorial.start") : String(localized: "tutorial.next")) {
                    if step == 4 {
                        AppHaptics.light()
                        session.finishTutorial(template: template, petID: petID, hasPlusAccess: subscriptions.hasPlusAccess)
                    } else {
                        withAnimation { step += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.coral)
            }
            .padding(20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $subscriptions.isPaywallPresented) {
            PaywallView()
                .environment(subscriptions)
        }
        .onAppear {
            template = session.lastTemplate
            petID = PetCharacter.resolvedID(session.lastPetID, hasPlusAccess: subscriptions.hasPlusAccess)
            demoStore.load(template: template, petID: petID)
        }
        .onChange(of: step) { _, value in
            if value == 3 {
                demoStore.load(template: template, petID: petID)
                demoStore.state.followMode = true
                demoStore.state.pawTrailEnabled = true
            }
        }
        .onChange(of: template) { _, value in
            demoStore.load(template: value, petID: petID)
        }
        .onChange(of: petID) { _, value in
            demoStore.selectPet(PetCharacter.character(id: value))
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.peach.opacity(0.5))
                    .frame(width: 220, height: 220)
                PetIllustration(character: PetCharacter.character(id: "dog-corgi"))
                    .frame(width: 180, height: 180)
            }
            Text("tutorial.welcome.title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("tutorial.welcome.body")
                .font(.body)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("tutorial.upload.note")
                .font(.footnote.weight(.medium))
                .foregroundStyle(AppTheme.coral)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var templatePage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("tutorial.template.title")
                .font(.title2.bold())
                .padding(.horizontal, 20)
            Text("tutorial.template.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TemplateKind.allCases) { item in
                        Button {
                            template = item
                        } label: {
                            VStack(spacing: 8) {
                                TemplateSceneView(template: item, palette: item.defaultPalette)
                                    .frame(width: 110, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                Text(LocalizedStringKey(item.nameKey))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .padding(8)
                            .background(.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(item == template ? AppTheme.coral : Color.clear, lineWidth: 3)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()
        }
        .padding(.top, 12)
    }

    private var petPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("tutorial.pet.title")
                .font(.title2.bold())
                .padding(.horizontal, 20)
            Text("tutorial.pet.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(PetCharacter.catalog) { pet in
                        let locked = !subscriptions.isPetUnlocked(pet.id)
                        Button {
                            if subscriptions.requestPet(pet.id) {
                                petID = pet.id
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 4) {
                                    PetIllustration(character: pet)
                                        .frame(height: 90)
                                        .opacity(locked ? 0.55 : 1)
                                    Text(LocalizedStringKey(pet.nameKey))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                        .lineLimit(1)
                                }
                                .padding(8)
                                .background(.white)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(!locked && pet.id == petID ? AppTheme.coral : Color.clear, lineWidth: 3)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                if locked {
                                    PlusLockBadge()
                                        .padding(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(LocalizedStringKey(pet.nameKey)))
                        .accessibilityHint(Text(locked ? "a11y.plus.locked" : "a11y.pet.hint"))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 12)
    }

    private var followPage: some View {
        VStack(spacing: 12) {
            Text("tutorial.follow.title")
                .font(.title2.bold())
            Text("tutorial.follow.body")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            WallpaperCanvasView(store: demoStore, showsSelection: false)
                .aspectRatio(9 / 19.5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 48)
                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            Spacer()
        }
        .padding(.top, 12)
    }

    private var exportPage: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.coral)
            Text("tutorial.export.title")
                .font(.title2.bold())
            Text("tutorial.export.body")
                .font(.body)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }
}
