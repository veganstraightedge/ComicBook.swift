// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ComicBook",
  platforms: [
    .macOS(.v26),
    .iOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "ComicBook",
      targets: ["ComicBook"]
    ),
    .executable(
      name: "comicbook",
      targets: ["ComicBookCLI"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/veganstraightedge/ComicInfo.swift.git", from: "1.1.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/tsolomko/SWCompression.git", from: "4.9.1"),
    // PLzmaSDK's C target uses unsafe build flags, so SPM forbids a version requirement.
    // Pin the exact commit of tag 1.6.1 (reproducible) instead of tracking a branch.
    .package(url: "https://github.com/OlehKulykov/PLzmaSDK.git", revision: "f449bc3e13204b68a7e05fca80ce8c31642085ec")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ComicBook",
      dependencies: [
        .product(name: "ComicInfo", package: "ComicInfo.swift"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "SWCompression", package: "SWCompression"),
        .product(name: "PLzmaSDK", package: "PLzmaSDK")
      ],
      resources: [.copy("Resources")]
    ),
    .executableTarget(
      name: "ComicBookCLI",
      dependencies: [
        "ComicBook",
        .product(name: "ComicInfo", package: "ComicInfo.swift"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    ),
    .testTarget(
      name: "ComicBookTests",
      dependencies: [
        "ComicBook"
      ],
      resources: [.copy("Fixtures")]
    ),
  ]
)
