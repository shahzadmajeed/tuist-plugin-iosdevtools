import ProjectDescription

let config = Config(
    plugins: [
        .git(url: "https://github.com/shahzadmajeed/DKBuildTools", tag: "0.0.1"),
        .git(url: "https://github.com/tuist/tuist-plugin-lint", tag: "0.3.0")
    ]
)
