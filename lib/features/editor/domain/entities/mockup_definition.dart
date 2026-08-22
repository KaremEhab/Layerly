import 'layer_enums.dart';

class MockupDefinition {
  final MockupDevice device;
  final String name;
  final double physicalWidthMm;
  final double physicalHeightMm;
  final double screenWidthPx;
  final double screenHeightPx;
  final double cornerRadius;
  final double bezelWidth;
  final double dynamicIslandWidth;
  final double dynamicIslandHeight;
  final double dynamicIslandTop;
  final bool hasDynamicIsland;
  final bool hasNotch;

  const MockupDefinition({
    required this.device,
    required this.name,
    required this.physicalWidthMm,
    required this.physicalHeightMm,
    required this.screenWidthPx,
    required this.screenHeightPx,
    this.cornerRadius = 52.0,
    this.bezelWidth = 6.0,
    this.dynamicIslandWidth = 105.0,
    this.dynamicIslandHeight = 29.0,
    this.dynamicIslandTop = 11.0,
    this.hasDynamicIsland = true,
    this.hasNotch = false,
  });

  double get physicalAspectRatio => physicalWidthMm / physicalHeightMm;
  double get screenAspectRatio => screenWidthPx / screenHeightPx;

  // Apple iPhone 17 Pro Max specs: 78.0 × 163.4 mm, 1320 × 2868 px
  static const iphone17ProMax = MockupDefinition(
    device: MockupDevice.iphone17ProMax,
    name: 'iPhone 17 Pro Max',
    physicalWidthMm: 78.0,
    physicalHeightMm: 163.4,
    screenWidthPx: 1320.0,
    screenHeightPx: 2868.0,
    cornerRadius: 52.0,
    bezelWidth: 6.0,
    dynamicIslandWidth: 105.0,
    dynamicIslandHeight: 29.0,
    dynamicIslandTop: 11.0,
    hasDynamicIsland: true,
  );

  // Apple iPhone 17 Pro specs: 71.5 × 149.6 mm, 1206 × 2622 px
  static const iphone17Pro = MockupDefinition(
    device: MockupDevice.iphone17Pro,
    name: 'iPhone 17 Pro',
    physicalWidthMm: 71.5,
    physicalHeightMm: 149.6,
    screenWidthPx: 1206.0,
    screenHeightPx: 2622.0,
    cornerRadius: 48.0,
    bezelWidth: 5.5,
    dynamicIslandWidth: 98.0,
    dynamicIslandHeight: 28.0,
    dynamicIslandTop: 10.0,
    hasDynamicIsland: true,
  );

  static const iphone = MockupDefinition(
    device: MockupDevice.iphone,
    name: 'iPhone 16 Pro',
    physicalWidthMm: 71.5,
    physicalHeightMm: 149.6,
    screenWidthPx: 1206.0,
    screenHeightPx: 2622.0,
    cornerRadius: 48.0,
    bezelWidth: 6.0,
    dynamicIslandWidth: 98.0,
    dynamicIslandHeight: 28.0,
    dynamicIslandTop: 10.0,
    hasDynamicIsland: true,
  );

  static const android = MockupDefinition(
    device: MockupDevice.android,
    name: 'Android Phone (Pixel/Galaxy)',
    physicalWidthMm: 76.5,
    physicalHeightMm: 162.8,
    screenWidthPx: 1440.0,
    screenHeightPx: 3120.0,
    cornerRadius: 40.0,
    bezelWidth: 5.0,
    dynamicIslandWidth: 14.0,
    dynamicIslandHeight: 14.0,
    dynamicIslandTop: 12.0,
    hasDynamicIsland: false,
  );

  static const macbook = MockupDefinition(
    device: MockupDevice.macbook,
    name: 'MacBook Pro 16"',
    physicalWidthMm: 355.7,
    physicalHeightMm: 248.1,
    screenWidthPx: 3456.0,
    screenHeightPx: 2234.0,
    cornerRadius: 16.0,
    bezelWidth: 8.0,
    hasDynamicIsland: false,
    hasNotch: true,
  );

  static const ipadPro = MockupDefinition(
    device: MockupDevice.ipadPro,
    name: 'iPad Pro 13"',
    physicalWidthMm: 215.5,
    physicalHeightMm: 281.6,
    screenWidthPx: 2064.0,
    screenHeightPx: 2752.0,
    cornerRadius: 28.0,
    bezelWidth: 10.0,
    hasDynamicIsland: false,
  );

  static const appleWatch = MockupDefinition(
    device: MockupDevice.appleWatch,
    name: 'Apple Watch Ultra',
    physicalWidthMm: 44.0,
    physicalHeightMm: 49.0,
    screenWidthPx: 410.0,
    screenHeightPx: 502.0,
    cornerRadius: 38.0,
    bezelWidth: 8.0,
    hasDynamicIsland: false,
  );

  static const browser = MockupDefinition(
    device: MockupDevice.browser,
    name: 'Desktop Browser',
    physicalWidthMm: 340.0,
    physicalHeightMm: 220.0,
    screenWidthPx: 1920.0,
    screenHeightPx: 1080.0,
    cornerRadius: 14.0,
    bezelWidth: 0.0,
    hasDynamicIsland: false,
  );

  static MockupDefinition fromDevice(MockupDevice device) {
    switch (device) {
      case MockupDevice.iphone17ProMax:
        return iphone17ProMax;
      case MockupDevice.iphone17Pro:
        return iphone17Pro;
      case MockupDevice.iphone:
        return iphone;
      case MockupDevice.android:
        return android;
      case MockupDevice.macbook:
        return macbook;
      case MockupDevice.ipadPro:
        return ipadPro;
      case MockupDevice.appleWatch:
        return appleWatch;
      case MockupDevice.browser:
        return browser;
    }
  }
}
