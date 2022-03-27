// 
// MainCoordinator.swift
// 

import Foundation
import UIKit

struct MainCoordinatorImplementation {
    
}

class MainCoordinator: BaseCoordinator {
    private let implementation: MainCoordinatorImplementation
    
    var inputs: MainViewModelInput!
    var actions: MainViewModelAction!

    init(implementation: MainCoordinatorImplementation) {
        self.implementation = implementation
    }
    
    deinit {
        print("\(self) -- deinit")
    }

    override func setInput() {
        
        self.inputs = MainViewModelInput(
        )
    }
    
    override func setActions() {
        self.actions = MainViewModelAction(
        )
    }
    
    override func start() {
        let vc = self.createViewController(input: self.inputs, actions: self.actions)
        let nav = UINavigationController(rootViewController: vc)
        let option = TransitionOptions(direction: .fade, style: .linear, duration: .main)
        self.setRootVC(nav, options: option)

    }

}

protocol MainCoordinatorInjection {
    func createViewController(
        input: MainViewModelInput!,
        actions: MainViewModelAction!
    ) -> MainViewController
}

extension MainCoordinator: MainCoordinatorInjection {
    func createViewController(
        input: MainViewModelInput!,
        actions: MainViewModelAction!
    ) -> MainViewController {
        let viewModel = MainViewModel(input: inputs, actions: actions)
        let vc = MainViewController(viewModel: viewModel)
        return vc
    }
}

protocol MainCoordinatorAction {
    // MARK: Make Actions
}

extension MainCoordinator: MainCoordinatorAction {
    
}

