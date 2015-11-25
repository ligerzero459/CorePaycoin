#!/bin/sh

# Cleanup to start with a blank slate

rm -rf build
mkdir -p build

xcodebuild clean

# Update all headers to produce up-to-date combined headers.

./update_headers.rb

# Build iOS static libraries for simulator and for devices

xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinIOSlib -configuration Release -sdk iphonesimulator
mv build/libCorePaycoinIOS.a build/libCorePaycoinIOS-simulator.a

xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinIOSlib -configuration Release -sdk iphoneos
mv build/libCorePaycoinIOS.a build/libCorePaycoinIOS-device.a

# Merge simulator and device libs into one

lipo build/libCorePaycoinIOS-device.a build/libCorePaycoinIOS-simulator.a -create -output build/libCorePaycoinIOS.a
rm build/libCorePaycoinIOS-simulator.a
rm build/libCorePaycoinIOS-device.a

# Build the iOS frameworks for simulator and for devices

rm -f build/CorePaycoinIOS*.framework

xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinIOS -configuration Release -sdk iphonesimulator
mv build/CorePaycoinIOS.framework build/CorePaycoinIOS-simulator.framework

xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinIOS -configuration Release -sdk iphoneos

# Merge the libraries inside the frameworks

mv build/CorePaycoinIOS-simulator.framework/CorePaycoinIOS build/CorePaycoinIOS.framework/CorePaycoinIOS-simulator
mv build/CorePaycoinIOS.framework/CorePaycoinIOS build/CorePaycoinIOS.framework/CorePaycoinIOS-device

lipo build/CorePaycoinIOS.framework/CorePaycoinIOS-simulator build/CorePaycoinIOS.framework/CorePaycoinIOS-device \
		-create -output build/CorePaycoinIOS.framework/CorePaycoinIOS
		
# Update openssl includes to match framework header search path

./postprocess_openssl_includes_in_framework.rb build/CorePaycoinIOS.framework

# Delete the intermediate files
		
rm build/CorePaycoinIOS.framework/CorePaycoinIOS-device
rm build/CorePaycoinIOS.framework/CorePaycoinIOS-simulator
rm -rf build/CorePaycoinIOS-simulator.framework

# Build for OS X

xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinOSXlib -configuration Release
xcodebuild -project CorePaycoin.xcodeproj -target CorePaycoinOSX    -configuration Release

# Update openssl includes to match framework header search path

./postprocess_openssl_includes_in_framework.rb build/CorePaycoinOSX.framework

# Clean up

rm -rf build/CorePaycoin.build


# At this point all the libraries and frameworks are built and placed in the ./build 
# directory with names ending with -IOS and -OSX indicating their architectures. The 
# rest of the script renames them to have the same name without these suffixes. 

# If you build your project in a way that you would rather have the names differ, you 
# can uncomment the next line and stop the build process here.

#exit


# Moving the result to a separate location

BINARIES_TARGETDIR="binaries"

rm -rf ${BINARIES_TARGETDIR}

mkdir ${BINARIES_TARGETDIR}
mkdir ${BINARIES_TARGETDIR}/OSX
mkdir ${BINARIES_TARGETDIR}/iOS

# Move and rename the frameworks
mv build/CorePaycoinOSX.framework ${BINARIES_TARGETDIR}/OSX/CorePaycoin.framework
mv ${BINARIES_TARGETDIR}/OSX/CorePaycoin.framework/CorePaycoinOSX ${BINARIES_TARGETDIR}/OSX/CorePaycoin.framework/CorePaycoin

mv build/CorePaycoinIOS.framework ${BINARIES_TARGETDIR}/iOS/CorePaycoin.framework
mv ${BINARIES_TARGETDIR}/iOS/CorePaycoin.framework/CorePaycoinIOS ${BINARIES_TARGETDIR}/iOS/CorePaycoin.framework/CorePaycoin

# Move and rename the static libraries
mv build/libCorePaycoinIOS.a ${BINARIES_TARGETDIR}/iOS/libCorePaycoin.a
mv build/libCorePaycoinOSX.a ${BINARIES_TARGETDIR}/OSX/libCorePaycoin.a

# Move the headers
mv build/include ${BINARIES_TARGETDIR}/include

# Clean up
rm -rf build

# Remove +Tests.h headers from libraries and frameworks.
find ${BINARIES_TARGETDIR} -name '*+Tests.h' -print0 | xargs -0 rm


