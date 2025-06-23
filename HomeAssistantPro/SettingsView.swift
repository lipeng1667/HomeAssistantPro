import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        Text("Me")
                            .font(.title2).bold()
                        Spacer()
                        Image(systemName: "gearshape")
                    }
                    .padding(.top)
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    Text("Ethan Carter")
                        .font(.title).bold()
                    Text("View profile")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Member since 2021")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account").font(.headline)
                        HStack {
                            Image(systemName: "phone")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Phone Number").font(.subheadline)
                                Text("+1 (555) 123-4567").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "envelope")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Email").font(.subheadline)
                                Text("ethan.carter@email.com").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "lock")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Password").font(.subheadline)
                                Text("Password").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings").font(.headline)
                        HStack {
                            Image(systemName: "bell")
                                .frame(width: 32, height: 32)
                            Text("Notifications").font(.subheadline)
                        }
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .frame(width: 32, height: 32)
                            Text("Help").font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
} 