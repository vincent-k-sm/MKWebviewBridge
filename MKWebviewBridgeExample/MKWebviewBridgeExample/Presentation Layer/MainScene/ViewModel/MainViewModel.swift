// 
// MainViewModel.swift
// 

import Foundation

struct MainViewModelInput {
    
}

struct MainViewModelAction {
    
}

class MainViewModel: BaseViewModel<MainViewModelInput, MainViewModelAction> {
 
    // MARK: - Private Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareViewModel()
        self.setEvent()
        self.setData()
        
    }
    
    private func prepareViewModel() {
     
    }
    
    deinit {
        print("\(self) -- deinit")
    }
}

// MARK: - Event
extension MainViewModel {
    private func setEvent() {
        
    }
}

// MARK: - Data
extension MainViewModel {
    private func setData() {
        
    }
}

