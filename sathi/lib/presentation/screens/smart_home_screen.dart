import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../data/models/device.dart';

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Device> _devices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.getDevices();
      final devices = (response.data['devices'] as List)
          .map((d) => Device.fromJson(d))
          .toList();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _controlDevice(Device device, String action) async {
    try {
      await _apiClient.controlDevice(device.id, action);
      await _loadDevices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No devices yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDevices,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return _DeviceCard(
                            device: device,
                            onToggle: () => _controlDevice(
                              device,
                              device.isOn ? 'off' : 'on',
                            ),
                            onLockToggle: () => _controlDevice(
                              device,
                              device.status == 'locked' ? 'unlock' : 'lock',
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final VoidCallback onLockToggle;

  const _DeviceCard({
    required this.device,
    required this.onToggle,
    required this.onLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = device.isOn;

    return Card(
      elevation: isOn ? 4 : 1,
      color: isOn
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDeviceIcon(device.type),
              size: 48,
              color: isOn
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              device.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              device.status.toUpperCase(),
              style: TextStyle(
                color: isOn ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (device.type == DeviceType.lock)
              ElevatedButton(
                onPressed: onLockToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: device.status == 'locked'
                      ? Colors.green
                      : Colors.orange,
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: Text(
                  device.status == 'locked' ? 'Unlock' : 'Lock',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else
              Switch(
                value: isOn,
                onChanged: (_) => onToggle(),
                activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).primaryColor;
                  }
                  return null;
                }),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.thermostat:
        return Icons.thermostat;
      case DeviceType.lock:
        return Icons.lock;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.sensor:
        return Icons.sensors;
      case DeviceType.switchDevice:
        return Icons.toggle_on;
    }
  }
}
