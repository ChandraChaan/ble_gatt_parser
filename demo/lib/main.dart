import 'dart:async';

import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter/material.dart';

import 'simulated_devices.dart';

const _amber = Color(0xFFEFA23F);
const _background = Color(0xFF0A0C0F);
const _surface = Color(0xFF14171B);
const _muted = Color(0xFF7D8691);
const _mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5);

void main() => runApp(const PlaygroundApp());

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ble_gatt_parser playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _amber,
          brightness: Brightness.dark,
          primary: _amber,
          surface: _surface,
        ),
        scaffoldBackgroundColor: _background,
      ),
      home: const PlaygroundPage(),
    );
  }
}

/// One notification: the bytes a device sent and what the parser made of them.
class Sample {
  const Sample(this.bytes, this.value, this.reading);

  final List<int> bytes;
  final GattValue value;
  final Reading reading;
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  static const _historyLength = 40;

  final _devices = simulatedDevices();
  final _latest = <SimulatedDevice, Sample>{};
  final _history = <SimulatedDevice, List<double>>{};
  late final Timer _timer;
  var _selected = 0;

  @override
  void initState() {
    super.initState();
    // Warm up every device so the charts start full.
    for (var i = 0; i < _historyLength; i++) {
      _receiveAll();
    }
    _timer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => setState(_receiveAll),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _receiveAll() {
    for (final device in _devices) {
      final bytes = device.nextNotification();
      final value = GattParser.parse(device.uuid, bytes);
      final reading = device.describe(value);
      _latest[device] = Sample(bytes, value, reading);
      final history = _history.putIfAbsent(device, () => []);
      history.add(reading.chartValue);
      if (history.length > _historyLength) history.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = _devices[_selected];
    final sample = _latest[device]!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final content = ListView(
              padding: EdgeInsets.all(wide ? 28 : 16),
              children: [
                const _Header(),
                const SizedBox(height: 20),
                if (!wide) ...[
                  _DeviceChips(
                    devices: _devices,
                    selected: _selected,
                    onSelected: (i) => setState(() => _selected = i),
                  ),
                  const SizedBox(height: 16),
                ],
                _ReadingCard(
                  device: device,
                  reading: sample.reading,
                  history: _history[device]!,
                ),
                const SizedBox(height: 16),
                _BytesCard(uuid: device.uuid, bytes: sample.bytes),
                const SizedBox(height: 16),
                _ParsedCard(value: sample.value),
                const SizedBox(height: 16),
                _TryYourOwnCard(devices: _devices),
              ],
            );
            if (!wide) return content;
            return Row(
              children: [
                NavigationRail(
                  backgroundColor: _surface,
                  extended: true,
                  minExtendedWidth: 230,
                  selectedIndex: _selected,
                  onDestinationSelected: (i) => setState(() => _selected = i),
                  destinations: [
                    for (final d in _devices)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.name),
                      ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: content,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ble_gatt_parser playground',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Simulated Bluetooth devices send real GATT notifications. '
          'The package turns the raw bytes into typed Dart objects.',
          style: text.bodyMedium?.copyWith(color: _muted),
        ),
      ],
    );
  }
}

class _DeviceChips extends StatelessWidget {
  const _DeviceChips({
    required this.devices,
    required this.selected,
    required this.onSelected,
  });

  final List<SimulatedDevice> devices;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < devices.length; i++)
          ChoiceChip(
            avatar: Icon(devices[i].icon, size: 18),
            label: Text(devices[i].name),
            selected: i == selected,
            onSelected: (_) => onSelected(i),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.device,
    required this.reading,
    required this.history,
  });

  final SimulatedDevice device;
  final Reading reading;
  final List<double> history;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: device.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                reading.headline,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: _amber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reading.unit,
                style: const TextStyle(color: _muted, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (final entry in reading.details.entries)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    Text(entry.value, style: const TextStyle(fontSize: 16)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(painter: _SparklinePainter(history)),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final range = high - low == 0 ? 1 : high - low;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - low) / range * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(fill, Paint()..color = _amber.withValues(alpha: 0.12))
      ..drawPath(
        path,
        Paint()
          ..color = _amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => true;
}

String _hex(int value, {int width = 2}) =>
    value.toRadixString(16).toUpperCase().padLeft(width, '0');

class _BytesCard extends StatelessWidget {
  const _BytesCard({required this.uuid, required this.bytes});

  final int uuid;
  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Raw notification on 0x${_hex(uuid, width: 4)}',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final byte in bytes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2A2F36)),
              ),
              child: Text(_hex(byte), style: _mono),
            ),
        ],
      ),
    );
  }
}

class _ParsedCard extends StatelessWidget {
  const _ParsedCard({required this.value});

  final GattValue value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'GattParser.parse(uuid, bytes)',
      child: SelectableText(value.toString(), style: _mono),
    );
  }
}

class _TryYourOwnCard extends StatefulWidget {
  const _TryYourOwnCard({required this.devices});

  final List<SimulatedDevice> devices;

  @override
  State<_TryYourOwnCard> createState() => _TryYourOwnCardState();
}

class _TryYourOwnCardState extends State<_TryYourOwnCard> {
  final _controller = TextEditingController(text: '16 50 00 04 80 03');
  var _uuid = GattCharacteristics.heartRateMeasurement;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _result() {
    final text = _controller.text.replaceAll(RegExp(r'0x|[\s,]'), '');
    if (text.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(text)) {
      return 'Enter bytes as hex, like 16 50 00 04 80 03';
    }
    final bytes = [
      for (var i = 0; i < text.length; i += 2)
        int.parse(text.substring(i, i + 2), radix: 16),
    ];
    try {
      return GattParser.parse(_uuid, bytes).toString();
    } on FormatException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Try your own bytes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<int>(
            value: _uuid,
            isExpanded: true,
            onChanged: (uuid) => setState(() => _uuid = uuid!),
            items: [
              for (final device in widget.devices)
                DropdownMenuItem(
                  value: device.uuid,
                  child: Text(
                    '0x${_hex(device.uuid, width: 4)}  ${device.name}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            style: _mono,
            decoration: const InputDecoration(
              hintText: 'Bytes in hex',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SelectableText(_result(), style: _mono),
        ],
      ),
    );
  }
}
