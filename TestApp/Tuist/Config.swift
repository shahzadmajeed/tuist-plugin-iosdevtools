import ProjectDescription

let config = Config(
    plugins: [
        .local(path: .relativeToManifest("../../LocalPlugins")),
        .git(url: "https://github.com/shahzadmajeed/tuist-plugin-iosdevtools", tag: "0.0.6"),
        .git(url: "https://github.com/tuist/tuist-plugin-lint", tag: "0.3.0")
    ]
)
