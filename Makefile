run:
	swift run
zig:
	swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

xcode:
	swift package generate-xcodeproj --xcconfig-overrides settings.xcconfig
	open zig.xcodeproj



