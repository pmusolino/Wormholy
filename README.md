<p align="center">
  <img src="https://raw.githubusercontent.com/pmusolino/Wormholy/master/logo.png" alt="Icon"/>
</p>

  [![Language](https://img.shields.io/badge/Swift-5-orange.svg)]()
  [![Pod version](https://img.shields.io/badge/Cocoapods-Compatible%20-blue)](https://cocoapods.org/pods/Wormholy)
  [![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-yellow.svg)](https://github.com/Carthage/Carthage)
  
  Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  
  
  **What you can do:**
  
  - [x] No code to write and no imports.
  - [x] Record all app traffic that uses `NSURLSession`.
  - [x] Reveal the content of all requests, responses, and headers simply by shaking your phone!
  - [x] No headaches with SSL certificates on HTTPS calls.
  - [x] Find, isolate and fix bugs quickly.
  - [x] Swift & Objective-C compatibility.
  - [x] Also works with external libraries like `Alamofire` & `AFNetworking`.
  - [x] Ability to blacklist hosts from being recorded using the array `ignoredHosts`.
  - [x] Ability to export API requests as Postman collection
  - [x] Ability to share cURL rappresentation of API requests
  
<p align="center">
<img src="https://raw.githubusercontent.com/pmusolino/Wormholy/master/screens.png" alt="Icon"/>
</p>
  
## Requirements
----------------

- iOS 11.0+
- Xcode 10+
- Swift 4, 4.1, 4.2 and Swift 5


## Usage
----------------
Add it to your project, and that's all! **Shake your device** or your simulator and Wormholy will appear! You don't need to import the library into your code, it works magically!

I suggest you install it only in debug mode. The easiest way is with CocoaPods:

```
pod 'Wormholy', :configurations => ['Debug']
``` 


If you want to disable the shake, and fire Wormholy from another point inside your app, you need to set the [environment variable](https://medium.com/@derrickho_28266/xcode-custom-environment-variables-681b5b8674ec) `WORMHOLY_SHAKE_ENABLED` = `NO`, and call this local notification:

```
NotificationCenter.default.post(name: NSNotification.Name(rawValue: "wormholy_fire"), object: nil)
```

You can also programmatically enable/disable the shake gesture at any time. You can do `Wormholy.shakeEnabled = false` to disable (or enable) the shake gesture. 



## Carthage
----------------

You can also install Wormholy using [Carthage](https://github.com/Carthage/Carthage).

To integrate Wormholy into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pmusolino/Wormholy"
```
Run `carthage update` to build the framework and drag the built `Wormholy.framework` into your Xcode project.

## Contributing

- If you **need help** or you'd like to **ask a general question**, open an issue.
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.


## Acknowledgements

**Made with ❤️ by [Paolo Musolino](https://github.com/pmusolino).**

***Follow me on:***
#### 💼 [Linkedin](https://www.linkedin.com/in/paolomusolino/)

#### 🤖 [Twitter](https://twitter.com/pmusolino)

#### 🌇 [Instagram](https://www.instagram.com/pmusolino/)

#### 👨🏼‍🎤 [Facebook](https://www.facebook.com/paolomusolino)

## MIT License
----------------
Wormholy is available under the MIT license. See the LICENSE file for more info.
