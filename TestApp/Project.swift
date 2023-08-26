import ProjectDescription
import LocalPlugin
import iOSDevTools

/*
                +-------------+
                |             |
                |     App     | Contains DKBuildTools App target and DKBuildTools unit-test target
                |             |
         +------+-------------+-------+
         |         depends on         |
         |                            |
 +----v-----+                   +-----v-----+
 |          |                   |           |
 |   Kit    |                   |     UI    |   Two independent frameworks to share code and start modularising your app
 |          |                   |           |
 +----------+                   +-----------+

 */

// MARK: - Project

let localPlugin = LocalHelper()
let removePlugin = DependenciesHelper()


// Creates our project using a helper function defined in ProjectDescriptionHelpers
let project = Project.app(name: "DKBuildTools",
                          platform: .iOS,
                          additionalTargets: ["DKBuildToolsKit", "DKBuildToolsUI"])
