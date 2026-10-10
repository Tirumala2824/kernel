import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/tokens.dart';
import 'routes_client.dart';

/// One sighting pin with its accuracy circle. [title] is shown in the
/// on-device info window only (a date, never the species or notes).
@immutable
class MapPin {
  const MapPin({
    required this.id,
    required this.position,
    required this.accuracyMeters,
    required this.title,
  });

  final String id;
  final GeoPoint position;
  final double accuracyMeters;
  final String title;
}

@immutable
class MapViewData {
  const MapViewData({
    required this.pins,
    required this.selectedId,
    required this.route,
    required this.onSelect,
  });

  final List<MapPin> pins;
  final String? selectedId;

  /// Decoded route polyline; empty when no route is shown.
  final List<GeoPoint> route;
  final ValueChanged<String> onSelect;
}

typedef MapViewBuilder =
    Widget Function(BuildContext context, MapViewData data);

/// The Google map. Tests replace it so no platform view is created.
final mapViewBuilderProvider = Provider<MapViewBuilder>(
  (ref) =>
      (context, data) => GoogleSightingsMap(data: data),
  name: 'mapViewBuilderProvider',
);

LatLng _ll(GeoPoint p) => LatLng(p.latitude, p.longitude);

class GoogleSightingsMap extends StatefulWidget {
  const GoogleSightingsMap({super.key, required this.data});

  final MapViewData data;

  @override
  State<GoogleSightingsMap> createState() => _GoogleSightingsMapState();
}

class _GoogleSightingsMapState extends State<GoogleSightingsMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant GoogleSightingsMap old) {
    super.didUpdateWidget(old);
    final selected = _selected;
    if (selected != null && old.data.selectedId != widget.data.selectedId) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_ll(selected.position)));
    }
  }

  MapPin? get _selected {
    for (final pin in widget.data.pins) {
      if (pin.id == widget.data.selectedId) return pin;
    }
    return widget.data.pins.firstOrNull;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final focus = _selected;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        // The screen only builds the map when there is at least one pin.
        target: focus == null ? const LatLng(0, 0) : _ll(focus.position),
        zoom: focus == null ? 1 : 17,
      ),
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (c) => _controller = c,
      markers: {
        for (final pin in data.pins)
          Marker(
            markerId: MarkerId(pin.id),
            position: _ll(pin.position),
            infoWindow: InfoWindow(title: pin.title),
            onTap: () => data.onSelect(pin.id),
          ),
      },
      circles: {
        for (final pin in data.pins)
          Circle(
            circleId: CircleId('acc-${pin.id}'),
            center: _ll(pin.position),
            radius: pin.accuracyMeters,
            strokeWidth: 2,
            strokeColor: KernelColors.forest,
            fillColor: KernelColors.forest.withValues(alpha: 0.12),
          ),
      },
      polylines: {
        if (data.route.length >= 2)
          Polyline(
            polylineId: const PolylineId('route'),
            points: [for (final p in data.route) _ll(p)],
            width: 5,
            color: KernelColors.amber,
          ),
      },
    );
  }
}
