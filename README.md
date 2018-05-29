# Wormholy

  [![Language](https://img.shields.io/badge/Swift-4-orange.svg)]()
  
  Start debugging iOS network calls like a wizard, without extra code! Wormholy makes debugging quick and reliable.
  
  
  **What you can do:**
  
  - [x] Record all the app traffic that use NSURLSession.
  - [x] Reveal the content of all requests, responses and headers shaking your phone!
  - [x] No headaches with SSL certificates on HTTPS calls.
  - [x] Search and delete bugs quickly.
  - [x] Swift & Objective-C compatibility
  - [x] Works also with external libraries like Alamofire & AFNetworking.
  
## Usage
----------------
Add it to your project, and that's all! **Shake your device** or your simulator and Wormholy will appear! You don't need to import the library into your code, it works magically!

I suggest you to install it only in debug mode. The easy way is to use cocoapods:

```
pod 'Wormholy', :git => 'https://github.com/pmusolino/Wormholy', :configurations => ['Debug']
``` 


## Contributing

- If you **need help** or you'd like to **ask a general question**, open an issue.
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.


## Acknowledgements

Made with ❤️ by [Paolo Musolino](https://github.com/pmusolino).


## MIT License
----------------
Wormholy is available under the MIT license. See the LICENSE file for more info.