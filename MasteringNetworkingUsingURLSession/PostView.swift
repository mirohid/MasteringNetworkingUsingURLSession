



import SwiftUI
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
// MARK: - Model
struct Post: Codable, Identifiable {
    let id: Int
    var title: String
    var body: String
}
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//




//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
// MARK: - ViewModel
class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var errorMessage: String?
    
    private let baseURL = "https://jsonplaceholder.typicode.com/posts"
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
    
    
    
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
    // Fetch Posts (GET)
    func fetchPosts() {
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                return
            }
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                DispatchQueue.main.async { self.posts = posts }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }.resume()
    }
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    
    
    
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    // Create Post (POST)
    func createPost(title: String, body: String) {
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            return
        }
        
        let post: [String: Any] = ["title": title, "body": body, "userId": 1]
        guard let requestData = try? JSONSerialization.data(withJSONObject: post) else {
            errorMessage = "Failed to encode post data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                return
            }
            do {
                let newPost = try JSONDecoder().decode(Post.self, from: data)
                DispatchQueue.main.async { self.posts.append(newPost) }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }.resume()
    }
    
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    
    
    
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    // Update Post (PUT)
    func updatePost(postId: Int, title: String, body: String) {
        guard let url = URL(string: "\(baseURL)/\(postId)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        let updatedPost: [String: Any] = ["title": title, "body": body, "userId": 1]
        guard let requestData = try? JSONSerialization.data(withJSONObject: updatedPost) else {
            errorMessage = "Failed to encode post data"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.errorMessage = "No data received" }
                return
            }
            do {
                let updatedPost = try JSONDecoder().decode(Post.self, from: data)
                DispatchQueue.main.async {
                    if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                        self.posts[index] = updatedPost
                    }
                }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }.resume()
    }
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    
    
    
    
    //--------------------------------------------------------------------------------------//
    //--------------------------------------------------------------------------------------//
    // Delete Post (DELETE)
    func deletePost(postId: Int) {
        guard let url = URL(string: "\(baseURL)/\(postId)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            DispatchQueue.main.async { self.posts.removeAll { $0.id == postId } }
        }.resume()
    }
}
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//



//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
// MARK: - View
struct PostView: View {
    @StateObject var viewModel = PostViewModel()
    @State private var isAddingPost = false
    @State private var editingPost: Post?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.title)
                            .font(.headline)
                        Text(post.body)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        editingPost = post
                    }
                }
                .onDelete(perform: deletePost)
            }
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingPost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
            .onAppear {
                viewModel.fetchPosts()
            }
            .sheet(isPresented: $isAddingPost) {
                AddEditPostView(viewModel: viewModel, post: nil)
            }
            .sheet(item: $editingPost) { post in
                AddEditPostView(viewModel: viewModel, post: post)
            }
        }
    }

    private func deletePost(at offsets: IndexSet) {
        for index in offsets {
            let post = viewModel.posts[index]
            viewModel.deletePost(postId: post.id)
        }
    }
}
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//





//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
// MARK: - Add/Edit View
struct AddEditPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var postBody: String
    var viewModel: PostViewModel
    var post: Post?

    init(viewModel: PostViewModel, post: Post?) {
        self.viewModel = viewModel
        self.post = post
        _title = State(initialValue: post?.title ?? "")
        _postBody = State(initialValue: post?.body ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(post == nil ? "New Post" : "Edit Post")) {
                    TextField("Title", text: $title)
                    TextField("Body", text: $postBody)
                }
                Button(action: savePost) {
                    Text(post == nil ? "Add Post" : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(post == nil ? Color.blue : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle(post == nil ? "Add Post" : "Edit Post")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func savePost() {
        guard !title.isEmpty, !postBody.isEmpty else { return }
        if let post = post {
            viewModel.updatePost(postId: post.id, title: title, body: postBody)
        } else {
            viewModel.createPost(title: title, body: postBody)
        }
        presentationMode.wrappedValue.dismiss()
    }
}
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//





//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
    }
}
//------------------------------------------------------------------------------------//
//-------------------------------------------------------------------------------------//
