import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../models/map_features/map_features_controller.dart';
import '../../models/map_features/map_overlay.dart';
import '../../models/map_features/poi_categories.dart';
import '../../models/map_features/station.dart';
import '../../screens/settings_screen.dart';

class MapFeaturesPanel extends StatelessWidget {
  final MapFeaturesController controller;

  const MapFeaturesPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PointerInterceptor(
      child: Drawer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Toggle Visibilities',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildRailwayTile(context, theme),

                  const Divider(height: 24, thickness: 1),

                  _buildBordersTile(context, theme),

                  const Divider(height: 24, thickness: 1),

                  for (final category in kPoiCategories) _buildPoiTile(category),

                  const Divider(height: 32, thickness: 1),
                  Text(
                    'The data of these locations is from www.openstreetmap.org. The data is made available under ODbL.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRailwayTile(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
          title: Row(
            children: [
              const Icon(Icons.train, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(child: Text('Stations', style: theme.textTheme.titleMedium)),
              controller.isFetchingStations
                  ? const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Switch(
                      value: controller.anyStationTypeVisible,
                      onChanged: controller.toggleStations,
                      activeTrackColor: theme.colorScheme.primary,
                    ),
            ],
          ),
          children: [
            _buildStationTile(
              title: 'Train Stations',
              value: controller.showTrainStations,
              isLoading: controller.isFetchingTrainStations,
              onChanged: (v) => controller.toggleStationType(StationType.trainStation, v),
              icon: const Icon(Icons.train_outlined, color: Colors.indigo),
            ),
            _buildStationTile(
              title: 'Subway Stations',
              value: controller.showSubwayStations,
              isLoading: controller.isFetchingSubwayStations,
              onChanged: (v) => controller.toggleStationType(StationType.subway, v),
              icon: const Icon(Icons.subway_outlined, color: Colors.purple),
            ),
            _buildStationTile(
              title: 'Tram Stops',
              value: controller.showTramStops,
              isLoading: controller.isFetchingTramStops,
              onChanged: (v) => controller.toggleStationType(StationType.tram, v),
              icon: const Icon(Icons.tram_outlined, color: Color(0xFF8A2BE2)),
            ),
            _buildStationTile(
              title: 'Bus Stops',
              value: controller.showBusStops,
              isLoading: controller.isFetchingBusStops,
              onChanged: (v) => _handleBusStopsToggle(context, v),
              icon: const Icon(Icons.directions_bus_outlined, color: Color(0xFFDA70D6)),
            ),
            _buildStationTile(
              title: 'Ferry Terminals',
              value: controller.showFerryStops,
              isLoading: controller.isFetchingFerryStops,
              onChanged: (v) => controller.toggleStationType(StationType.ferry, v),
              icon: const Icon(Icons.directions_ferry_outlined, color: Color(0xFF0921AA)),
            ),
            if (controller.anyStationTypeVisible)
              _buildStationTile(
                title: 'Hiding Zones',
                value: controller.showHidingZones,
                isLoading: false,
                onChanged: controller.toggleHidingZones,
                icon: const Icon(Icons.visibility, color: Colors.teal),
              ),
          ],
        ),
      ),
    );
  }

  void _handleBusStopsToggle(BuildContext context, bool value) {
    if (value && !controller.busStopsWarningDismissed) {
      _showBusStopsWarningDialog(context);
    } else {
      controller.toggleStationType(StationType.bus, value);
    }
  }

  void _showBusStopsWarningDialog(BuildContext context) {
    bool dontAskAgain = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Performance Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enabling Bus Stops can significantly impact performance. \n'
                'This feature is not recommended for large play areas.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontAskAgain,
                    onChanged: (value) {
                      setState(() => dontAskAgain = value ?? false);
                    },
                  ),
                  const Expanded(child: Text("Don't ask again")),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (dontAskAgain) {
                  controller.dismissBusStopsWarning();
                }
                controller.toggleStationType(StationType.bus, true);
                Navigator.of(context).pop();
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationTile({
    required String title,
    required bool value,
    required bool isLoading,
    required ValueChanged<bool> onChanged,
    required Icon icon,
  }) {
    return ListTile(
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 4, right: 4),
      leading: icon,
      onTap: isLoading ? null : () => onChanged(!value),
      trailing: isLoading
          ? Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 14.0),
              child: const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildBordersTile(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
          title: Row(
            children: [
              const Icon(Icons.border_outer, color: Colors.brown),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'experimental',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text('Borders', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),

              controller.isFetchingOverlays
                  ? const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Switch(
                      value: controller.anyOverlayTypeVisible,
                      onChanged: controller.toggleOverlays,
                    ),
            ],
          ),
          children: [
            _buildOverlayTile(
              title: 'International',
              value: controller.showBorderInternational,
              isLoading: controller.isFetchingBorderInters,
              onChanged: (v) => controller.toggleOverlay(MapOverlayType.borderInter, v),
            ),
            _buildOverlayTile(
              title: 'Level 1 Division',
              value: controller.showBorder1AD,
              isLoading: controller.isFetchingBorder1ADs,
              onChanged: (v) => controller.toggleOverlay(MapOverlayType.border1AD, v),
            ),
            _buildOverlayTile(
              title: 'Level 2 Division',
              value: controller.showBorder2AD,
              isLoading: controller.isFetchingBorder2ADs,
              onChanged: (v) => controller.toggleOverlay(MapOverlayType.border2AD, v),
            ),
            _buildOverlayTile(
              title: 'Level 3 Division',
              value: controller.showBorder3AD,
              isLoading: controller.isFetchingBorder3ADs,
              onChanged: (v) => controller.toggleOverlay(MapOverlayType.border3AD, v),
            ),
            _buildOverlayTile(
              title: 'Level 4 Division',
              value: controller.showBorder4AD,
              isLoading: controller.isFetchingBorder4ADs,
              onChanged: (v) => controller.toggleOverlay(MapOverlayType.border4AD, v),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  '/settings',
                  arguments: const SettingsRouteArgs(openAdvanced: true),
                );
              },
              child: Text(
                'Adjust division levels →',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayTile({
    required String title,
    required bool value,
    required bool isLoading,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 4, right: 4),
      leading: const Icon(Icons.timeline, color: Colors.brown),
      onTap: isLoading ? null : () => onChanged(!value),
      trailing: isLoading
          ? Padding(
              padding: const EdgeInsets.only(left: 4, right: 14),
              child: const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildPoiTile(PoiCategory category) {
    final value = controller.isPoiVisible(category);
    final isLoading = controller.isPoiFetching(category);
    onChanged(bool b) => controller.togglePoi(category, b);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.only(left: 16, right: 16),
        leading: Icon(category.panelIcon, color: category.color),
        title: Text(category.title, style: const TextStyle(fontSize: 16)),
        onTap: () => onChanged(!value),
        trailing: isLoading
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Switch(value: value, onChanged: onChanged, activeTrackColor: category.color),
      ),
    );
  }
}
