// 
// CommonWebViewModel.swift
// 

import Foundation
import MKWebview

struct CommonWebViewModelInput {
    var config: MKWebViewConfiguration?
}

struct CommonWebViewModelAction {
    
}

class CommonWebViewModel: BaseViewModel<CommonWebViewModelInput, CommonWebViewModelAction> {
 
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
extension CommonWebViewModel {
    private func setEvent() {
        
    }
}

// MARK: - Data
extension CommonWebViewModel {
    private func setData() {
        
    }
}

