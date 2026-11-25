//
//  BarcodeScannerViewModelTests.swift
//  ChofiTests
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import AVFoundation
import XCTest
@testable import Chofi

private struct MockCameraAuthorizer: CameraAuthorizing {
    var status: AVAuthorizationStatus
    var isCameraAvailable = true
    var grantsAccess = false

    func requestAccess() async -> Bool {
        grantsAccess
    }
}

@MainActor
final class BarcodeScannerViewModelTests: XCTestCase {

    private func makeViewModel(
        status: AVAuthorizationStatus,
        isCameraAvailable: Bool = true,
        grantsAccess: Bool = false
    ) -> BarcodeScannerViewModel {
        BarcodeScannerViewModel(camera: MockCameraAuthorizer(
            status: status,
            isCameraAvailable: isCameraAvailable,
            grantsAccess: grantsAccess
        ))
    }

    func testInitialStateIsCheckingPermission() {
        let viewModel = makeViewModel(status: .authorized)

        XCTAssertEqual(viewModel.state, .checkingPermission)
        XCTAssertNil(viewModel.scannedCode)
    }

    func testAuthorizedStartsScanning() async {
        let viewModel = makeViewModel(status: .authorized)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .scanning)
    }

    func testNotDeterminedGrantedStartsScanning() async {
        let viewModel = makeViewModel(status: .notDetermined, grantsAccess: true)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .scanning)
    }

    func testNotDeterminedRejectedIsPermissionDenied() async {
        let viewModel = makeViewModel(status: .notDetermined, grantsAccess: false)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .permissionDenied)
    }

    func testDeniedIsPermissionDenied() async {
        let viewModel = makeViewModel(status: .denied)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .permissionDenied)
    }

    func testRestrictedIsPermissionDenied() async {
        let viewModel = makeViewModel(status: .restricted)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .permissionDenied)
    }

    func testNoCameraIsCameraUnavailable() async {
        let viewModel = makeViewModel(status: .authorized, isCameraAvailable: false)

        await viewModel.start()

        XCTAssertEqual(viewModel.state, .cameraUnavailable)
    }

    func testHandleStoresFirstCode() {
        let viewModel = makeViewModel(status: .authorized)

        viewModel.handle(code: "7501055363803")

        XCTAssertEqual(viewModel.scannedCode, "7501055363803")
    }

    func testHandleIgnoresLaterCodes() {
        let viewModel = makeViewModel(status: .authorized)

        viewModel.handle(code: "7501055363803")
        viewModel.handle(code: "12345670")

        XCTAssertEqual(viewModel.scannedCode, "7501055363803")
    }

    func testHandleIgnoresEmptyCodes() {
        let viewModel = makeViewModel(status: .authorized)

        viewModel.handle(code: "")
        viewModel.handle(code: "   ")

        XCTAssertNil(viewModel.scannedCode)
    }

    func testHandleKeepsLeadingZeroUnchanged() {
        let viewModel = makeViewModel(status: .authorized)

        viewModel.handle(code: "0012345678905")

        XCTAssertEqual(viewModel.scannedCode, "0012345678905")
    }
}
