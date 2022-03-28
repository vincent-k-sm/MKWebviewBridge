// 
// CommonWebViewCoordinator.swift
// 

import Foundation
import UIKit
import MKWebview

struct CommonWebViewCoordinatorImplementation {
    var config: MKWebViewConfiguration?
}

class CommonWebViewCoordinator: BaseCoordinator {
    private let implementation: CommonWebViewCoordinatorImplementation
    
    var inputs: CommonWebViewModelInput!
    var actions: CommonWebViewModelAction!

    init(implementation: CommonWebViewCoordinatorImplementation) {
        self.implementation = implementation

    }
    
    deinit {
        print("\(Self.self) -- deinit")
    }

    override func setInput() {
        self.inputs = CommonWebViewModelInput(
            config: self.implementation.config
        )
    }
    
    override func setActions() {
        self.actions = CommonWebViewModelAction(
        )
    }
    
    override func start() {
        let vc = self.createViewController(input: self.inputs, actions: self.actions)
        vc.configuration = self.implementation.config
        let nav = UINavigationController(rootViewController: vc)
        let options = TransitionOptions(direction: .fade, style: .easeIn, duration: .main)
        self.setRootVC(nav, options: options)

    }

}

protocol CommonWebCoordinatorInjection {
    func createViewController(
        input: CommonWebViewModelInput!,
        actions: CommonWebViewModelAction!
    ) -> CommonWebViewController
}

extension CommonWebViewCoordinator: CommonWebCoordinatorInjection {
    func createViewController(
        input: CommonWebViewModelInput!,
        actions: CommonWebViewModelAction!
    ) -> CommonWebViewController {
        let viewModel = CommonWebViewModel(input: inputs, actions: actions)
        let vc = CommonWebViewController(viewModel: viewModel)
        return vc
    }
}

protocol CommonWebCoordinatorAction {
    // MARK: Make Actions
}

extension CommonWebViewCoordinator: CommonWebCoordinatorAction {
    
}

