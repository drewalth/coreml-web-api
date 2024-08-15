# coreml-web-api

Deploy [CoreML](https://developer.apple.com/documentation/coreml) models on the server with [Vapor](https://vapor.codes/)

![hero image](./Image.png)

> This is a prototype project to demonstrate one way to deploy CoreML models on the server with Vapor. It is not intended for production use.

## Prerequisites

- Xcode 15 (client)
- Swift 5.5

## Getting started

1. Clone repo
2. Open terminal and navigate to the project directory
3. open the project with Xcode. `xed .`
4. `cd server && swift run`
5. Back in Xcode, set the development team in `Signing & Capabilities` to your own team/profile
7. Select the `Run` scheme of your choice and run the project in Xcode
8. On simulator, select `Photo Library` then one of the default images, then `Upload Image`
9. Get results!

> NOTE: additional steps may (most likely will) be required to run the project on a physical device.
> see [The Serve Command](https://docs.vapor.codes/advanced/server/#serve-command) about binding to host and port.

--- 

Source code for the article [Deploy CoreML Models on the Server with Vapor](https://medium.com/@drewalth/deploy-coreml-models-on-the-server-with-vapor-48809a853fae)
