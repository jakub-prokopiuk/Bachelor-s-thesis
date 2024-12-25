import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  double minPower = 0;
  double? maxPower;
  List<String> selectedConnectorTypes = [];

  void openFilterDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FilterWidget(
          minPower: minPower,
          maxPower: maxPower,
          selectedConnectorTypes: selectedConnectorTypes,
          onApply: (updatedMinPower, updatedMaxPower, updatedConnectorTypes) {
            Navigator.of(context).pop({
              'minPower': updatedMinPower,
              'maxPower': updatedMaxPower,
              'connectorTypes': updatedConnectorTypes,
            });
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        minPower = result['minPower'];
        maxPower = result['maxPower'];
        selectedConnectorTypes = result['connectorTypes'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: openFilterDialog,
          child: const Text('Open Filters'),
        ),
      ),
    );
  }
}

class FilterWidget extends StatefulWidget {
  final double minPower;
  final double? maxPower;
  final List<String> selectedConnectorTypes;
  final Function(
    double minPower,
    double? maxPower,
    List<String>? connectorTypes,
  ) onApply;

  const FilterWidget({
    super.key,
    required this.minPower,
    required this.maxPower,
    required this.selectedConnectorTypes,
    required this.onApply,
  });

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late double minPower;
  late double? maxPower;
  late List<String> selectedConnectorTypes;

  final List<Map<String, dynamic>> connectorTypes = [
    {
      'type': 'Type 2',
      'icon': Icons.car_rental,
      'dbValue': 'IEC62196Type2CableAttached',
    },
    {
      'type': 'Type 3',
      'icon': Icons.electric_bolt,
      'dbValue': 'IEC62196Type3',
    },
    {
      'type': 'Type 2 Outlet',
      'icon': Icons.power,
      'dbValue': 'IEC62196Type2Outlet',
    },
    {
      'type': 'Tesla',
      'icon': Icons.car_repair,
      'dbValue': 'Tesla',
    },
    {
      'type': 'Chademo',
      'icon': Icons.car_crash,
      'dbValue': 'Chademo',
    },
    {
      'type': 'CCS',
      'icon': Icons.energy_savings_leaf,
      'dbValue': 'IEC62196Type2CCS',
    },
  ];

  @override
  void initState() {
    super.initState();
    minPower = widget.minPower;
    maxPower = widget.maxPower;
    selectedConnectorTypes = List<String>.from(widget.selectedConnectorTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                const Text('Min Power (kW)'),
                Column(
                  children: [
                    Slider(
                      value: minPower,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: minPower.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          minPower = (value / 10).roundToDouble() * 10;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Text(minPower.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Max Power (kW)'),
                Column(
                  children: [
                    Slider(
                      value: maxPower ?? 100,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: maxPower == null
                          ? '>100'
                          : maxPower!.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          maxPower = value == 100
                              ? null
                              : (value / 10).roundToDouble() * 10;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                    Text(
                      maxPower == null ? '>100' : maxPower!.toStringAsFixed(0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Connector Types'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: connectorTypes.map((connector) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 48) / 3,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final dbValue = connector['dbValue'];
                            if (selectedConnectorTypes.contains(dbValue)) {
                              selectedConnectorTypes.remove(dbValue);
                            } else {
                              selectedConnectorTypes.add(dbValue);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedConnectorTypes
                                    .contains(connector['dbValue'])
                                ? Colors.green
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                connector['icon'],
                                size: 30,
                                color: selectedConnectorTypes
                                        .contains(connector['dbValue'])
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                connector['type'],
                                style: TextStyle(
                                  color: selectedConnectorTypes
                                          .contains(connector['dbValue'])
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          minPower,
                          maxPower,
                          selectedConnectorTypes.isNotEmpty
                              ? selectedConnectorTypes
                              : null,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: const Text(
              'Filter Chargers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }
}
