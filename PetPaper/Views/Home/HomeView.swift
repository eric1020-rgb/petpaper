import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                tutorialCard
                Text("home.section.templates")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 20)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(TemplateKind.allCases) { template in
                        Button {
                            session.openEditor(template: template)
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("home.title")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.ink)
            Text("home.subtitle")
                .font(.body)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var tutorialCard: some View {
        Button {
            session.replayTutorial()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.tutorial")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("home.tutorial.caption")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

struct TemplateCard: View {
    let template: TemplateKind

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottom) {
                TemplateSceneView(template: template, palette: template.defaultPalette)
                PetIllustration(character: previewPet)
                    .frame(width: 78, height: 88)
                    .offset(y: 8)
            }
            .aspectRatio(9 / 16, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(LocalizedStringKey(template.nameKey))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(LocalizedStringKey(template.captionKey))
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(2)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
    }

    private var previewPet: PetCharacter {
        switch template {
        case .pastel, .sakura: return PetCharacter.character(id: "cat-calico")
        case .nightSky, .neon: return PetCharacter.character(id: "cat-tuxedo")
        case .park, .beach: return PetCharacter.character(id: "dog-corgi")
        case .cozyRoom: return PetCharacter.character(id: "cat-tabby")
        case .snow: return PetCharacter.character(id: "dog-husky")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppSession())
}
