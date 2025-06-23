import SwiftUI

struct ForumView: View {
    @State private var searchText = ""
    @State private var selectedTopic: Topic? = nil
    let topics = [
        Topic(id: 1, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle"),
        Topic(id: 2, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle"),
        Topic(id: 3, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle")
    ]
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Community")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Image(systemName: "pencil")
                        .padding(.trailing)
                }
                .padding(.top)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding([.horizontal, .bottom])
                List(topics) { topic in
                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                        HStack(spacing: 16) {
                            Image(systemName: topic.avatar)
                                .resizable()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.title)
                                    .font(.headline)
                                Text("\(topic.comments) comments • \(topic.likes) likes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
    }
}

struct Topic: Identifiable {
    let id: Int
    let title: String
    let comments: Int
    let likes: Int
    let avatar: String
} 