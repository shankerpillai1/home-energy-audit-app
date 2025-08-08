
1. Install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install --cask flutter

brew install cocoapods

xcode-select --install

sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

2. flutter doctor -v

3. Log in to Apple ID in Xcode
Open Xcode

Go to: Xcode → Settings → Accounts

Click + → choose Apple ID → log in with your Apple ID

4. Download Your Project

cd ~/Desktop
git clone <YOUR_GITHUB_REPO_URL>
cd <YOUR_PROJECT_FOLDER>
flutter pub get

5. Prepare iOS Project
cd ios
pod install
cd ..
open ios/Runner.xcworkspace

In Xcode:

Select Runner in the left panel

Go to TARGETS → Runner → Signing & Capabilities

Check Automatically manage signing

Set Team to your Apple ID

Change Bundle Identifier to something unique (e.g., com.yourname.myapp)

6. Connect and Enable Developer Mode on iPad
Plug iPad into Mac via cable

On iPad: tap Trust → enter passcode

In Xcode: go to Window → Devices and Simulators

Confirm your iPad appears in the list

Try running the app once (⌘R) — iPad will prompt to enable Developer Mode

On iPad:

Go to: Settings → Privacy & Security → Developer Mode

Turn it ON → Restart iPad → Confirm Enable