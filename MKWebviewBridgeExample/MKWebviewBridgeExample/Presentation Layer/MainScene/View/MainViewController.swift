// 
// MainViewController.swift
// 

import UIKit

class MainViewController: BaseViewController<MainViewModel> {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.bindViewModel()
        self.viewModel.viewDidLoad()
        self.bindEvent()

    }

    deinit {
        print("\(self) -- deinit")
    }
}

extension MainViewController {
    private func setUI() {

    }
}

extension MainViewController {
    private func bindViewModel() {
        
    }
}

extension MainViewController {
    private func bindEvent() {

    }
}


