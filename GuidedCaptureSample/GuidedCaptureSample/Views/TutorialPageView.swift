import SwiftUI

struct Section: Identifiable {
    let id = UUID()
    let title: String
    let body: [String]
    let symbol: String?
    let symbolColor: Color?
}

struct TutorialPageView: View {
    let pageName: String
    let imageName: String
    let imageCaption: String
    let sections: [Section]

    var body: some View {
        GeometryReader { geomReader in
            let height = geomReader.size.height * 0.5
            ZStack {
                VStack {
                    Spacer()
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Spacer().frame(height: height)
                }

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(pageName)
                            .foregroundColor(.primary)
                            .font(.largeTitle)
                            .bold()
                        Text(imageCaption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: height)

                    SectionView(sections: sections)
                        .frame(height: height)
                }
            }
            .navigationBarTitle(pageName, displayMode: .inline)
        }
    }
}

private struct SectionView: View {
    let sections: [Section]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(sections) { section in
                Divider()
                    .padding(.bottom, 5.0)

                HStack {
                    Text(section.title)
                        .bold()

                    Spacer()

                    if let symbol = section.symbol, let symbolColor = section.symbolColor {
                        Text(Image(systemName: symbol))
                            .bold()
                            .foregroundColor(symbolColor)
                    }
                }

                ForEach(section.body, id: \.self) { line in
                    Text(line)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("HIDDEN SPACER")
                    .hidden()
            }
        }
    }
}
