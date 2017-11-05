.PHONY: zig
zig:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

.PHONY: zig-release
release:
	swift build -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

.PHONY: run
run: 
	swift run -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"


xcode: zig.xcodeproj
	swift package generate-xcodeproj --xcconfig-overrides settings.xcconfig
	open zig.xcodeproj



