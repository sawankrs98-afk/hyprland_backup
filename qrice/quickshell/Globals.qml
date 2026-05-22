pragma Singleton
import QtQuick

QtObject {
    // Menu States
    property bool wifiOpen: false
    property bool bluetoothOpen: false
    property bool batteryOpen: false
    property bool brightnessOpen: false
    property bool volumeOpen: false
    property bool notificationsOpen: false
    property bool calendarOpen: false
    
    // INDEPENDENT TEXT TOGGLES
    property bool showWifiSpeed: false
    property bool showBatteryPercent: false
    property bool showVolumePercent: false
    
    // HARDWARE POWER STATES
    property bool isWifiOn: true
    property bool isWifiConnected: true
    
    property bool isBluetoothOn: true
    property bool isScanning: false
    property bool showNetworkSpeed: true
}
