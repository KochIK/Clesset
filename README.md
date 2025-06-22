# Clesset
A cli tool for detecting unused image assets in iOS projects.\
Clesset supports multiple built-in search strategies, including `Swift`, `Objective-C`, and `R.swift`.\
Notice that this project doesn't use complex filters or regular expressions.\
The idea is simple — it should work right away, without any extra setup or confusion.


> [!NOTE]
> The current version of the project has no tests and contains some rough edges.
> I plan to fix this soon.

## Motivation
There are many tools on GitHub that try to find unused image assets.
But none of them worked well on a **relly** big iOS projects.
So I decided to build my own.

If you find this helpful for your work, I’ll be happy!🙂

## How It Works
Clesset parses `.imageset` resources and searches for their usage in `*.m` and `*.swift` files using several strategies.
#### Strategies:
* Search in `*.m` files using the pattern `"<resource_name>"`
* Search in `*.swift` files using the pattern `"<resource_name>"`
* Search in `*.swift` files using the pattern `R.image.<rswift_resource_name>`
* Search in `*.swift` files using the pattern `<rswift_resource_name>`. Used for specific formatting cases. (`R\n.image\n.someImage`)
## Installation
```shell
> mint install kochik/clesset
> clesset -h
```
## Usage
#### Commands
```shell
> clesset analyze <project-path> <resources-path>
> clesset clear <project-path> <resources-path>
```
#### Options
```
-f <f>  Ignore specific file or folder paths during the search.
For example: `*.generated.swift`, `*/Generated/*`


-s <s>  Exclude specific search strategies from analysis.
Using `*DoubleCheck` strategies is recommended for broader coverage, especially with R.swift.
  Available values:
  * `objc` – search .m files for `"<name>"`
  * `swift` – search .swift files for `"<name>"`
  * `rSwift` – search .swift files for `R.image.<rswift_name>`
  * `simpleDoubleCheck` – search .m and .swift for `<name>`
  * `rSwiftDoubleCheck` – search .swift for `<rswift_name>` (extra R.swift coverage)
```
#### Example usage
```shell
> clesset analyze /Users/user/project /Users/user/project/resources -f "*.generated.swift" "*/Generated/*"

Run analyze with config:
Project path: /Users/user/project
Resources path: /Users/user/project/resources
Excluded paths: ["*.generated.swift", "*/Generated/*"]
Excluded strategies: []

Detected 8 resources.
Summary
image_1
 └── ContentView.swift
image#_3
 └── ContentView.swift
image_2
 └── ContentView.swift

Total resources: 8 / 6324224 bytes
Used resources: 3 / 1634304 bytes
Unused resources: 5 / 4689920 bytes
Total time: 0.0085
```
## License and Information
Clesset is open-sourced under the MIT license.

If you find a bug or have a suggestion, feel free to open [an issue](https://github.com/kochik/clesset/issues/new)!
