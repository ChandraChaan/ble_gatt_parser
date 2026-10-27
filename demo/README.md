# ble_gatt_parser playground

A Flutter web app that shows [ble_gatt_parser](https://pub.dev/packages/ble_gatt_parser) at work. Simulated Bluetooth devices send spec-correct GATT notifications, and the app shows the raw bytes next to what the parser makes of them. You can also paste your own bytes.

Live at **https://chandrachaan.github.io/ble_gatt_parser/**

Run it locally:

```bash
cd demo
flutter run -d chrome
```

The devices are simulated, so no Bluetooth hardware is needed. In a real app, you pass the bytes from your BLE plugin's notifications to `GattParser.parse` in the same way.
