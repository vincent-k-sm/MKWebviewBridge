# MKWebViewBridge


## 소개  
* 개인 프로젝트에서 공통으로 사용되는 웹뷰를 프레임워크화 합니다

- [Requirements](#requirements)
- [Installation](#installation)
- [Features](#features)


<br><br>

## Requirements

| Platform | Minimum Swift Version | Installation | Status |
| --- | --- | --- | --- |
| iOS 13.0+ / macOS 11.0+ | 5.0 | [Swift Package Manager](#swift-package-manager), [Manual](#manually) | Fully Tested |

<br><br>

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift package set up, adding MKWebViewBridge as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/vincent-k-sm/MKWebviewBridge", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate MKWebViewBridge into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

  ```bash
  $ git init
  ```

- Add MKWebView as a git [submodule](https://github.com/vincent-k-sm/MKWebviewBridge) by running the following command:

  ```bash
  $ git submodule add https://github.com/vincent-k-sm/MKWebviewBridge
  ```
    > After download We Suggest Remove `Example` Folder When Embed

- Click on the `+` button under th Frameworks, Libraries, and Embedded Content
- Click on the `Add Other` and Select in `MKFoundation` folder
- Drag the `MKFoundation` folder into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.
    
- And that's it!

<br><br>

## Features
* [x] [Common WebView Configuration](#common-webview-configuration)
    * [x] Custom Navigation Bar by Configurdation (Deeplink Parameters)
    * [x] Using Common ProcessPool
* [x] Common Webview Controller
    * [x] [Initial Header](#initial-header)
    * [x] [Initial Cookies](#initial-cookies)
        * [x] [Remove Cookies](#remove-cookies)
    * [x] [Load url based](#load-url-based)
    * [x] [Load local html file based](load-local-html-file-based)
    * [x] [Adding Custom User Scripts](adding-custom-user-scripts)
    * [x] [Handle JavaScripts](#handle-javascripts)
    * [x] [Evalutate JavaScripts](#evalutate-javascripts)
    * [x] [Reload Webview](#reload-webview)
* [x] Example App





<br><br>

## Example


- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

  ```bash
  $ git init
  ```

- Add MKWebView as a git [submodule](https://github.com/vincent-k-sm/MKWebviewBridge) by running the following command:

  ```bash
  $ git submodule add https://github.com/vincent-k-sm/MKWebviewBridge
  $ cd MKWebviewBridgeExample
  ```
    > https://github.com/vincent-k-sm/MKWebviewBridge/tree/master/MKWebviewBridgeExample

<br><br>

## Common WebView Configuration
### MKWebViewConfiguration.swift
```swift
/// Webview를 세팅하는 MKWebViewConfiguration 입니다
/// - Parameters:
///   - host: deeplink 에 활용되는 host가 적용됩니다 (plist 내 등록된 url Types를 모두 체크합니다)
///   - urlString: landing url 을 설정합니다
///   - title: 네비게이션 바 내 페이지 타이틀을 설정합니다
///   - leftBtn: 좌측 버튼 (<-) 을 활성화 합니다
///   - rightBtn: 우측 버튼 (x) 을 활성화 합니다
///   - navigationColor: 네비게이션 바의 색상을 지정합니다 (hexString)
///   - statusBarColor: 상단 스테이터스 바의 색상을 지정합니다 (hexString)
///   - tintColor: 네비게이션 바 내 버튼, 타이틀 등의 색상을 지정합니다 (hexString)
///   - removeStack:기존 stack 에 쌓여있는 모든  controller를 제거합니다
///   - navigationBarIsEnable: 
///     -> host, urlString, navigationBarIsEnable, removeStack 값에 따라 네비게이션바 노출 여부를 설정합니다
///   - important:
///     -> host, urlString, navigationBarIsEnable, removeStack 을 제외하고 모든 value가 nil 인 경우 네비게이션바가 노출되지 않습니다
public struct MKWebViewConfiguration: Codable {
    public var host: String                = ""
    public var urlString: String           = ""
    public var title: String?              = nil
    public var leftBtn: Bool?              = nil
    public var rightBtn: Bool?             = nil
    public var navigationColor: String?    = nil
    public var statusBarColor: String?     = nil
    public var tintColor: String?          = nil
    public var removeStack: Bool?          = nil
    public var navigationBarIsEnable: Bool = false
}
```
### USE CASE
* It's automatically pared from deeplink action
    * eg. 
    ```swift
    mkwebview://webview?url=https://smbh.kr/mk_bridge/sample
    &title=테스트
    &navigationColor=FFFFFF
    &tintColor=000000
    &statusBarColor=FFFFFF
    ```
* Even you can use in model input
    ```swift
    /// create option
    let configure = MKWebViewConfiguration(
        host: "webview",
        urlString: "https://smbh.kr/mk_bridge/sample",
        title: <#T##String?#>,
        leftBtn: <#T##Bool?#>,
        rightBtn: <#T##Bool?#>,
        navigationColor: <#T##String?#>,
        statusBarColor: <#T##String?#>,
        tintColor: <#T##String?#>,
        removeStack: <#T##Bool?#>
    )

    /// set configuration
    let vc = MKWebViewController()
    vc.configuration = configure
    self.pushViewController(vc, animated: true)
    ```
    
---

<br><br>


## Initial Header
### MKWebviewController
* For Apply Headers when load or reload
```swift
open func headers() -> [String: String] {
    return [:]
}
```
### USE CASE
```swift
private var headerInfos: [String: String] = [
    "Content-Type": "application/json",
    "app-device-uuid": UUID().uuidString,
    "app-device-os-version": UIDevice.current.systemVersion,
    "app-version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
    "access-token": "access-token",
    "refresh-token": "refresh-token-value"
]
----
override func headers() -> [String: String] {
    return self.headerInfos
}

```
---

<br><br>

## Initial Cookies
### MKWebviewController
* For Apply cookies when load or reload
```swift
open func cookies() -> [HTTPCookie] {
    return []
}
```
### USE CASE
```swift
override func cookies() -> [HTTPCookie] {
    var cookies: [HTTPCookie] = []
    if let uuidCookie = HTTPCookie(properties: [.domain: "smbh.kr",
                                                .path: "/",
                                                .name: "CID",
                                                .value: "\(UUID().uuidString)",
                                                .secure: "TRUE"]) { cookies.append(uuidCookie) }
    return cookies
}
```
<br><br>

## Remove Cookies
### MKWebviewController
* For Remove All Cookies

### USE CASE
```swift
WebkitManager.shared.removeCookies {
    //
}
```
or 
```swift
MKWebview.shared.clearCookies(completion: nil)
```
---

<br><br>

## Load url based
### MKWebviewController
* For Static URL Load
```swift
open func loadURLString() -> String? {
    return nil
}
```
### USE CASE
```swift
override func loadURLString() -> String? {
    return "https://smbh.kr/mk_bridge/sample"
}
```
---

<br><br>


## Load local html file based
### MKWebviewController
* For Static Local File Load
```swift
open func loadLocalFile() -> URL? {
    return nil
}
```
### USE CASE
```swift
override func loadLocalFile() -> URL? {
    guard let url = Bundle.main.url(forResource: "sampleScheme", withExtension: "html") else { return nil }
    return url
}
```
---

<br><br>


## Adding Custom User Scripts
### MKWebviewController
* For Custom Scripts
> can handle in `addPostMessageHandler(##String##)` on  `onAddPostMessage`
```swift
open func onAddUserScript() -> String? {
    return nil
}
```
### USE CASE
> eg. It can Called `window.CustomScripts.showToast('msg';)` in JavaScript
```swift
//// Add Script

override func onAddUserScript() -> String? {
    return """
        CustomScripts = {
            showToast(s) {
                window.webkit.messageHandlers.showToast.postMessage(s);
            },
        }
    """

/// Handle
override func onAddPostMessage() {
    addPostMessageHandler("showToast") { (res) in
        
        if let res = res as? String {
            Toast.shared.makeToast(res)
        }
    }
}
}
```
---

<br><br>


## Handle JavaScripts

### MKWebviewController
* For Handle Scripts
```swift
open func onAddPostMessage() {
    //
}
```
### USE CASE 1
> eg. It can Called `window.webkit.messageHandlers.showToast.postMessage('msg';)` in JavaScript
```swift
override func onAddPostMessage() {
    super.onAddPostMessage()
    addPostMessageHandler("showToast") { (res) in
        // do stuff
        if let res = res as? String {
            Toast.shared.makeToast(res)
        }
    }
}
```
### USE CASE 2
* It can make return data `(iOS 14.0 *)` when call Javascript with promise
> eg. It can Called `window.webkit.messageHandlers.showToast.postMessage('msg';)` in JavaScript
```swift
///--- javaScript ---
var promise = window.webkit.messageHandlers.testWithPromise.postMessage( inputInfo );
promise.then(
            function(result) {
                console.log(result); // "Stuff worked!"
                successFunc( result )
            },
            function(err) {
                console.log(err); // Error: "It broke"
                errorFunc( err )
            });

///--- override func onAddPostMessage() ---
if #available(iOS 14.0, *) {
    let promiseResult: ReplyHandler = ("Return Data", nil)
    addPostMessageReplyHandler("testWithPromise", handler: promiseResult, result: { result in
        print("Called")
    })
}

```
---

<br><br>

## Evalutate JavaScripts

### MKWebviewController
```swift
func evaluateJavascript(_ function: String, result: ((Bool, Any?) -> Void)?)
```
### USE CASE
```swift
let value = "javascript:setToken('NEW_ACSESS_TOKEN');"
self.evaluateJavascript(value) { (result, _ ) in
    Debug.print(result)
}
```
---


<br><br>

## Reload Webview

### MKWebviewController
```swift
public func reloadWebview()
```
### USE CASE
```swift
self.reloadWebview()
```
---

