import 'package:permission_handler/permission_handler.dart';

class BluetoothPrintService {

  String permissionPathUsed = 'Not checked yet';

  String getPermissionPathUsed() {
    return permissionPathUsed;
  }

  Future<bool> ensureBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      //Permission.locationWhenInUse,
      Permission.location
    ].request();

    final hasAndroid12BluetoothPermissions =
        (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);

    final hasLegacyLocationPermission =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (hasAndroid12BluetoothPermissions) {
      permissionPathUsed = 'Android 12+ (BLUETOOTH_SCAN + BLUETOOTH_CONNECT)';
      return true;
    }

    if (hasLegacyLocationPermission) {
      permissionPathUsed = 'Legacy Android (Location permission)';
      return true;
    }

    permissionPathUsed = 'Permission denied';
    return false;
  }

}