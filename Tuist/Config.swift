import ProjectDescription

let config = Config(
    plugins: [
        .local(path: .relativeToManifest("../../Plugins/DKBuildTools")),
        .git(url: "https://github.com/tuist/tuist-plugin-lint", tag: "0.3.0")
    ]
)
