#! /bin/bash
#
# Usage:
# sh ./build.sh --android --reload
#
#
# Check function OK
checkOK() {
	if [ $? != 0 ]; then
		echo "${OpenColor}${Red}* ERROR. Exiting...${CloseColor}"
		exit 1
	fi
}

# Configs
BUILDDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT="$BUILDDIR/../../obytebuilds/project-$1"

CURRENT_OS=$1

if [ -z "CURRENT_OS" ]
then
 echo "Build.sh WP8|ANDROID|IOS"
fi

CLEAR=false
DBGJS=false

if [[ $2 == "--clear" || $3 == "--clear" ]]
then
	CLEAR=true
fi

if [[ $2 == "--dbgjs" || $3 == "--dbgjs" ]]
then
	DBGJS=true
fi


echo "${OpenColor}${Green}* Checking dependencies...${CloseColor}"
command -v cordova >/dev/null 2>&1 || { echo >&2 "Cordova is not present, please install it: sudo npm install -g cordova."; exit 1; }
#command -v xcodebuild >/dev/null 2>&1 || { echo >&2 "XCode is not present, install it or use [--android]."; exit 1; }

# Create project dir
if $CLEAR
then
	if [ -d $PROJECT ]; then
		rm -rf $PROJECT
	fi
fi

echo "Build directory is $BUILDDIR"
echo "Project directory is $PROJECT"


if [ ! -d $PROJECT ]; then
	cd $BUILDDIR
	echo "${OpenColor}${Green}* Creating project... ${CloseColor}"
	cordova create ../../obytebuilds/project-$1 org.byteball.wallet Obyte
	checkOK

	cd $PROJECT

	if [ $CURRENT_OS == "ANDROID" ]; then
		echo "${OpenColor}${Green}* Adding Android platform... ${CloseColor}"
		cordova platforms add android
		checkOK
	fi

	if [ $CURRENT_OS == "IOS" ]; then
		echo "${OpenColor}${Green}* Adding IOS platform... ${CloseColor}"
		cordova platforms add ios
		checkOK
	fi

	if [ $CURRENT_OS == "WP8" ]; then
		echo "${OpenColor}${Green}* Adding WP8 platform... ${CloseColor}"
		cordova platforms add wp8
		checkOK
	fi

	echo "${OpenColor}${Green}* Installing plugins... ${CloseColor}"

	cordova plugin add phonegap-plugin-barcodescanner --variable ANDROID_SUPPORT_V4_VERSION="27.1.1"
	cordova plugin add cordova-plugin-statusbar
	cordova plugin add cordova-plugin-customurlscheme --variable URL_SCHEME=byteball
	cordova plugin add cordova-plugin-inappbrowser
	cordova plugin add cordova-plugin-x-toast && cordova prepare
	cordova plugin add cordova-clipboard
	cordova plugin add https://github.com/EddyVerbruggen/SocialSharing-PhoneGap-Plugin.git && cordova prepare
	cordova plugin add cordova-plugin-spinner-dialog
	cordova plugin add cordova-plugin-dialogs
	cordova plugin add cordova-plugin-file
	cordova plugin add cordova-plugin-touch-id && cordova prepare
	cordova plugin add cordova-ios-requires-fullscreen
	cordova plugin add https://github.com/byteball/cordova-sqlite-plugin.git
	cordova plugin add cordova-plugin-device-name@1.3.2
	cordova plugin add phonegap-plugin-push
	cordova plugin add cordova-android-referrer
	cordova plugin add cordova-plugin-mfilechooser
	cordova plugin add https://github.com/brodybits/me.apla.cordova.app-preferences#test1 #for cordova-android 8
	#cordova plugin add cordova-plugin-app-preferences #for cordova-android < 8
	cordova plugin add cordova-custom-config --fetch
	cordova plugin add https://github.com/kakysha/cordova-plugin-intent.git
	cordova plugin add cordova-plugin-android-permissions
fi

if $DBGJS
then
	echo "${OpenColor}${Green}* Generating obyte bundle (debug js)...${CloseColor}"
	cd $BUILDDIR/..
	grunt cordova
	checkOK
else
	echo "${OpenColor}${Green}* Generating obyte bundle...${CloseColor}"
	cd $BUILDDIR/..
	grunt cordova-prod
	checkOK
fi

echo "${OpenColor}${Green}* Copying files...${CloseColor}"
cd $BUILDDIR/..
mkdir $PROJECT/www
cp -af public/** $PROJECT/www
checkOK

echo "${OpenColor}${Green}* Copying initial database...${CloseColor}"
cp node_modules/ocore/initial-db/initial.byteball.sqlite $PROJECT/www
cp node_modules/ocore/initial-db/initial.byteball-light.sqlite $PROJECT/www
checkOK

node $BUILDDIR/replaceForPartialClient.js $PROJECT
rm $PROJECT/www/partialClient.html
checkOK

cd $BUILDDIR

cp config.xml $PROJECT/config.xml
checkOK

if [ $CURRENT_OS == "ANDROID" ]; then
	echo "Android project!!!"
	
	cat $BUILDDIR/android/android.css >> $PROJECT/www/css/obyte.css

	mkdir -p $PROJECT/platforms/android/res/xml/
	checkOK

#  cp android/AndroidManifest.xml $PROJECT/platforms/android/AndroidManifest.xml
#  checkOK
	
	cp android/build-extras.gradle $PROJECT/platforms/android/build-extras.gradle
	checkOK

	#cp android/project.properties $PROJECT/platforms/android/project.properties
	#checkOK

	cp -R android/res/* $PROJECT/platforms/android/res
	checkOK

	cp android/google-services.json $PROJECT/google-services.json
	checkOK
fi

if [ $CURRENT_OS == "IOS" ]; then

	echo "IOS project!!!"

	cp -R ios $PROJECT/../
	checkOK
#  mkdir -p $PROJECT/platforms/ios
#  checkOK
#
#  cp ios/Byteball-Info.plist $PROJECT/platforms/ios/Byteball-Info.plist
#  checkOK
#
#  mkdir -p $PROJECT/platforms/ios/Byteball/Resources/icons
#  checkOK
#
#  mkdir -p $PROJECT/platforms/ios/Byteball/Resources/splash
#  checkOK
#
#  cp -R ios/icons/* $PROJECT/platforms/ios/Byteball/Resources/icons
#  checkOK
#
#  cp -R ios/splash/* $PROJECT/platforms/ios/Byteball/Resources/splash
#  checkOK
fi

if [ $CURRENT_OS == "WP8" ]; then
	echo "Wp8 project!!!"
	cp -R $PROJECT/www/* $PROJECT/platforms/wp8/www
	checkOK
	if ! $CLEAR
	then
		cp -vf wp/Properties/* $PROJECT/platforms/wp8/Properties/
		checkOK
		cp -vf wp/MainPage.xaml $PROJECT/platforms/wp8/
		checkOK
		cp -vf wp/Package.appxmanifest $PROJECT/platforms/wp8/
		checkOK
		cp -vf wp/Assets/* $PROJECT/platforms/wp8/Assets/
		cp -vf wp/SplashScreenImage.jpg $PROJECT/platforms/wp8/
		cp -vf wp/ApplicationIcon.png $PROJECT/platforms/wp8/
		cp -vf wp/Background.png $PROJECT/platforms/wp8/
		checkOK
	fi
fi


