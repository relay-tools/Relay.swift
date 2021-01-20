workspace(
    name = "com_github_relay_tools_relay_swift"
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "d0e5f888b2ccce42c92e6d4686b5507b4230462627f965f9d39862e11ae9fb35",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/0.18.0/rules_swift.0.18.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()