# Build a great camera experience for iPhone Duo

## 3:00 - Understand AVCaptureDevicePosition
```swift
enum AVCaptureDevicePosition: Int {
    case unspecified
    case back
    case front
}

extension AVCaptureDevice {
    // ...
    var position: AVCaptureDevicePosition { get }
}
```

## 4:06 - Initialize a direction coordinator
```swift
directionCoordinator = AVCaptureDeviceDirectionCoordinator(
    view: view,
    deviceTypes: [
        .builtInOuterUltraWideCamera,
        .builtInInnerUltraWideCamera,
        .builtInDualWideCamera,
    ],
    changeHandler: { [weak self] map in
        self?.updateCameraSession(map)
    }
)
```

## 7:30 - Configure the video preview layer
```swift
class AVCaptureVideoPreviewLayer {
    // ...

    var videoGravity: AVLayerVideoGravity { get set }
}
```

## 7:51 - Select a dynamic aspect ratio
```swift
class AVCaptureDevice {
    // ...

    var dynamicAspectRatio: AVCaptureDevice.AspectRatio? { get }
}
```

## 8:34 - Disable sensor orientation compensation
```swift
// Disable for improved performance
class AVCapturePhotoOutput: AVCaptureOutput {
    // ...

    var isCameraSensorOrientationCompensationEnabled: Bool { get set }
}
```
