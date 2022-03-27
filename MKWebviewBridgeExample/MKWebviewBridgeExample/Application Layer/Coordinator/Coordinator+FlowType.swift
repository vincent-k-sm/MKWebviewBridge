//
//  Coordinator+FlowType.swift
//


import Foundation

enum FlowType{
    case main(_ implementation: MainCoordinatorImplementation)
}

extension BaseCoordinator {
    func flow(to flow: FlowType) -> BaseCoordinator {
        switch flow {
            case let .main(impl):
                return MainCoordinator(implementation: impl)
        }
    }
}
