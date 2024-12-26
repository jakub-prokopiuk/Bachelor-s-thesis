import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      appBar: AppBar(),
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
      'icon': 'assets/icons/Type2.svg',
      'dbValue': 'IEC62196Type2CableAttached',
    },
    {
      'type': 'Type 2 Outlet',
      'icon': 'assets/icons/Type2.svg',
      'dbValue': 'IEC62196Type2Outlet',
    },
    {
      'type': 'Type 3',
      'icon': 'assets/icons/Type3.svg',
      'dbValue': 'IEC62196Type3',
    },
    {
      'type': 'Tesla',
      'icon': 'assets/icons/Tesla.svg',
      'dbValue': 'Tesla',
    },
    {
      'type': 'Chademo',
      'icon': 'assets/icons/Chademo.svg',
      'dbValue': 'Chademo',
    },
    {
      'type': 'CCS',
      'icon': 'assets/icons/CCS2.svg',
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Align(
            alignment: Alignment.center,
            child: const Text(
              'Filter Chargers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
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
                        maxPower == null
                            ? '>100'
                            : maxPower!.toStringAsFixed(0),
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
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedConnectorTypes
                                        .contains(connector['dbValue'])
                                    ? Colors.green
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  connector['icon'],
                                  width: 30,
                                  height: 30,
                                  colorFilter: ColorFilter.mode(
                                    selectedConnectorTypes
                                            .contains(connector['dbValue'])
                                        ? Colors.white
                                        : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  connector['type'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          FocusScope.of(context).unfocus();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
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
                        child: const Text('Apply'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
