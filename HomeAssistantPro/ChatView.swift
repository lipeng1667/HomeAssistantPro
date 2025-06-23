import SwiftUI

struct ChatView: View {
    @State private var message: String = ""
    var body: some View {
        VStack {
            HStack {
                Text("Chat")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .padding(.top)
            ScrollView {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Support")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Hi there, I'm here to help. What can I help you?")
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            Spacer()
            HStack {
                TextField("Message", text: $message)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .padding(.horizontal)
    }
} 