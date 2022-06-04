# YOLOv5 - TensorFlow Lite Object Detection iOS Example Application

[korean readme](https://github.com/aqntks/yolov5-ios-tensorflow-lite/blob/main/README_korean.md)

**iOS Versions Supported:** iOS 12.0 and above.
**Xcode Version Required:** 10.0 and above

## Overview

This is a camera app that continuously detects the objects (bounding boxes and classes) in the frames seen by your device's back camera, using a [YOLOv5](https://github.com/ultralytics/yolov5) model. These instructions walk you through building and running the demo on an iOS device.

<!-- TODO(b/124116863): Add app screenshot. -->

## Prerequisites

* You must have Xcode installed

* You must have a valid Apple Developer ID

* The demo app requires a camera and must be executed on a real iOS device. You can build it and run with the iPhone Simulator but the app raises a camera not found exception.

* You don't need to build the entire TensorFlow library to run the demo, it uses CocoaPods to download the TensorFlow Lite library.

* You'll also need the Xcode command-line tools:
 ```xcode-select --install```
 If this is a new install, you will need to run the Xcode application once to agree to the license before continuing.
## Building the iOS Demo App

1. Install CocoaPods if you don't have it.
```sudo gem install cocoapods```

2. Install the pod to generate the workspace file:
```cd yolov5-ios-tensorflow-lite/```
```pod install```
  If you have installed this pod before and that command doesn't work, try
```pod update```
At the end of this step you should have a file called ```ObjectDetection.xcworkspace```

3. Open **ObjectDetection.xcworkspace** in Xcode.

4. Please change the bundle identifier to a unique identifier and select your development team in **'General->Signing'** before building the application if you are using an iOS device.

5. Build and run the app in Xcode.
You'll have to grant permissions for the app to use the device's camera. Point the camera at various objects and enjoy seeing how the model classifies things!

## Model Used

This app uses a [YOLOv5](https://github.com/ultralytics/yolov5) model.

To use YOLOv5's custom training model, convert it to a tflite model through export.py in the [YOLOv5 repository](https://github.com/ultralytics/yolov5).

```export.py --weights your_model.pt --include tflite```

## iOS App Details

The app is written entirely in Swift and uses the TensorFlow Lite
[Swift library](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/lite/swift)
for performing object detection.

The app is built using sample code from the [TensorFlow repository](https://github.com/tensorflow/examples).
