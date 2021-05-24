
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    init() {}
    
    final class Public: Content {
      var id: UUID?
      var name: String
      var username: String

      init(id: UUID?, name: String, username: String) {
        self.id = id
        self.name = name
        self.username = username
      }
    }
    
    init(id: UUID? = nil, name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
}

extension User {

  func convertToPublic() -> User.Public {
    return User.Public(id: id, name: name, username: username)
  }
}

extension EventLoopFuture where Value: User {
  func convertToPublic() -> EventLoopFuture<User.Public> {
    return self.map { user in
      return user.convertToPublic()
    }
  }
}

extension Collection where Element: User {
  func convertToPublic() -> [User.Public] {
    return self.map { $0.convertToPublic() }
  }
}

extension EventLoopFuture where Value == Array<User> {
  func convertToPublic() -> EventLoopFuture<[User.Public]> {
    return self.map { $0.convertToPublic() }
  }
}

extension User: ModelSessionAuthenticatable {}
extension User: ModelCredentialsAuthenticatable {}

// This i what causes the User model to conform to modelCredentialsAuthenticatable
extension User: ModelAuthenticatable {
  static let usernameKey = \User.$username
  static let passwordHashKey = \User.$password

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.password)
  }
}
