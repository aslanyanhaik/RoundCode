// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "RoundCode",
  platforms: [.iOS(.v13)],
  products: [.library(name: "RoundCode",targets: ["RoundCode"])],
  targets: [
    .target(name: "RoundCode", dependencies: [], path: "Sources"),
    .testTarget(name: "RoundCodeTests",dependencies: ["RoundCode"], path: "Tests")
  ]
)
