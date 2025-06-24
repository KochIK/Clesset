# Clesset
A cli tool for detecting unused image assets in iOS projects.\
Clesset supports multiple built-in search strategies, including `Swift`, `Objective-C`, and `R.swift`.\
Notice that this project doesn't use complex filters or regular expressions.\
The idea is simple — it should work right away, without any extra setup or confusion.


> [!NOTE]
> The current version of the project has no tests and contains some rough edges.
> I plan to fix this soon.

## Motivation
There are many tools on GitHub that try to find unused image assets, but none of them worked well on really big iOS projects.  
So I decided to build my own.

## How It Works
Clesset parses `.imageset` resources and searches for their usage in `*.m` and `*.swift` files using several strategies.
#### Strategies:
* Search in `*.m` files using the pattern `"<resource_name>"`
* Search in `*.swift` files using the pattern `"<resource_name>"`
* Search in `*.swift` files using the pattern `R.image.<rswift_resource_name>`
* Search in `*.swift` files using the pattern `.<rswift_resource_name>`. Used for specific formatting cases. (`R\n.image\n.someImage`)
## Installation
```shell
> mint install kochik/clesset
> clesset -h
```
## Usage
#### Commands
```shell
> clesset -summary <project-path> <resources-path>
> clesset -clear <project-path> <resources-path>
```
#### Options
```
--excPaths, -ep <excPaths> Ignore specific file or folder paths during the search.
For example: `*.generated.swift`, `*/Generated/*`

--excStrategies, -es <excStrategies> Exclude specific search strategies from analysis.
  Available values:
  * `objc` – search .m files for `"<name>"`
  * `swift` – search .swift files for `"<name>"`
  * `rSwift` – search .swift files for `R.image.<rswift_name>`
  * `rSwiftSimple` – search .swift for `.<rswift_name>` (extra R.swift coverage)
```
#### Example usage
```shell
> clesset -summary /Users/user/project /Users/user/project/resources -ep "*.generated.swift" "*/Generated/*"

Run with config:
Project path: /Users/user/project
Resources path: /Users/user/project/resources
Excluded paths: ["*.generated.swift", "*/Generated/*"]
Excluded strategies: []

Detected 8 resources.

Summary
Used:
┌──────────┬─────────────┬───────────────────┐
| Resource | Size(bytes) | Found at          |
├──────────┼─────────────┼───────────────────┤
| image_1  | 610304      | ContentView.swift |
├──────────┼─────────────┼───────────────────┤
| image_2  | 770048      | ContentView.swift |
└──────────┴─────────────┴───────────────────┘
Unused:
┌──────────┬─────────────┬──────────┐
| Resource | Size(bytes) | Found at |
├──────────┼─────────────┼──────────┤
| image_5  | 1425408     | None     |
├──────────┼─────────────┼──────────┤
| image_4  | 253952      | None     |
├──────────┼─────────────┼──────────┤
| image_6  | 1437696     | None     |
├──────────┼─────────────┼──────────┤
| image#_3 | 253952      | None     |
├──────────┼─────────────┼──────────┤
| image_7  | 1564672     | None     |
├──────────┼─────────────┼──────────┤
| image_8  | 8192        | None     |
└──────────┴─────────────┴──────────┘

Total resources: 8 = 6324224 bytes
Used resources: 2 = 1380352 bytes
Unused resources: 6 = 4943872 bytes
Total time: 0.008440017700195312
```
## License and Information
Clesset is open-sourced under the MIT license.

If you find a bug or have a suggestion, feel free to open [an issue](https://github.com/kochik/clesset/issues/new)!
