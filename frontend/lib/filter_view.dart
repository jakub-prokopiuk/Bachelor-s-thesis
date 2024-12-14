import 'package:flutter/material.dart';

class FilterWidget extends StatefulWidget {
  final Function(double minPower, double maxPower, List<String>? connectorTypes)
      onApply;

  const FilterWidget({
    super.key,
    required this.onApply,
  });

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  double minPower = 0;
  double maxPower = 100;
  List<String> selectedConnectorTypes = [];

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
                    ),
                    Text(minPower.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Max Power (kW)'),
                Column(
                  children: [
                    Slider(
                      value: maxPower,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: maxPower == 100
                          ? '>100'
                          : maxPower.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          maxPower = (value / 10).roundToDouble() * 10;
                        });
                      },
                    ),
                    Text(
                        maxPower == 100 ? '>100' : maxPower.toStringAsFixed(0)),
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
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
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
