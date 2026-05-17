//
//  MenuLoTests.swift
//  MenuLoTests
//

import XCTest
@testable import MenuLo

final class MenuLoTests: XCTestCase {
    
    func testUserModelDecoding() throws {
        let json = """
        {
            "user_id": 1,
            "username": "Test Kullanıcı",
            "email": "test@menulo.com",
            "role": "Customer"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "Test Kullanıcı")
        XCTAssertEqual(user.userType, .customer)
    }
    
    @MainActor
    func testAuthViewModelInitialState() {
        let vm = AuthViewModel()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.errorMessage, "")
    }
}
