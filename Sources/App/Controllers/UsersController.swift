
import Vapor

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get("login", use: loginHandler )
//        usersRoute.post("login", use: postLoginHandler)
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        credentialsAuthRoutes.post("login", use: postLoginHandler)
        
        basicAuthGroup.post("login", use: postLoginHandler)
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
//        this is the template for finding the eg tournaments for a given user
//        usersRoute.get(":userID", "tournaments", use: getTournamentsHandler)
        
    }
    
    func loginHandler(_ req: Request) -> EventLoopFuture<View> {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
          context = LoginContext(loginError: true)
        } else {
          context = LoginContext()
        }
        return req.view.render("login", context)
    }
    
    func postLoginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
      let user = try req.auth.require(User.self)
      let token = try Token.generate(for: user)
      return token.save(on: req.db).map { token }
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password) // this seemed to be missing, required to encrypt password
//        if in the context of an already created tournament, this may be where I have to add the child tournaments
//        to the user prior to saving and returninh – review the code in tournament
        return user.save(on: req.db).map { user.convertToPublic() }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on : req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }
}

struct LoginContext: Encodable {
  let title = "Log In"
  let loginError: Bool

  init(loginError: Bool = false) {
    self.loginError = loginError
  }
}
