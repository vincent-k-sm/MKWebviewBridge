//
//  Coordinator+FlowType.swift
//


import Foundation

enum FlowType{
    case webview(_ implementation: CommonWebViewCoordinatorImplementation)
}

extension BaseCoordinator {
    func flow(to flow: FlowType) -> BaseCoordinator {
        switch flow {
            case let .webview(impl):
                return CommonWebViewCoordinator(implementation: impl)
        }
    }
}
