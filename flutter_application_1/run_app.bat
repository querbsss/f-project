@echo off
cd /d "C:\Users\valen\OneDrive\Desktop\flatearth\flutter_application_1"
echo Current directory: %CD%
echo Checking for pubspec.yaml:
if exist pubspec.yaml (
    echo pubspec.yaml found
) else (
    echo pubspec.yaml NOT found
)
echo Running Flutter...
flutter run -d emulator-5554
pause
