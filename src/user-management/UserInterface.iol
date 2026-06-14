type UserRequest: void {
    .username: string
    .password: string
}

type UserResponse: void {
    .success: bool
    .message: string
}

interface UserInterface {
    RequestResponse:
        registerUser(UserRequest)(UserResponse),
        loginUser(UserRequest)(UserResponse),
        preflight(undefined)(undefined),
        preflightRegister(undefined)(undefined),
        preflightLogin(undefined)(undefined)
}