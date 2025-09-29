// lib/ui/home/tabs/retrofits_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Defines the data structure for a single retrofit action item.
class RetrofitItem {
  final String id;
  final String title;
  final String? subtitle;
  final bool enabled;
  final IconData icon;

  const RetrofitItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.enabled = true,
    required this.icon,
  });
}

/// Defines a section containing a list of [RetrofitItem]s.
class RetrofitSection {
  final String title;
  final List<RetrofitItem> items;
  const RetrofitSection({required this.title, required this.items});
}

/// A static catalog of all available retrofit sections and items.
/// The `enabled` flag controls whether an item is tappable.
const kRetrofitSections = <RetrofitSection>[
  RetrofitSection(
    title: 'LED Light Bulbs',
    items: [
      RetrofitItem(
        id: 'lighting_led',
        title: 'Switch to LED Bulbs',
        subtitle: 'Instant savings; longer life; lower heat.',
        icon: Icons.lightbulb_outline,
        enabled: true, // Changed to true to enable this retrofit
      ),
    ],
  ),
  RetrofitSection(
    title: 'Seal Air Leaks',
    items: [
      RetrofitItem(
        id: 'leakage',
        title: 'Seal Air Leaks (Doors/Windows)',
        subtitle: 'Find drafts and seal frames, sills, baseboards.',
        icon: Icons.water_damage_outlined,
        enabled: true,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Thermostat Settings',
    items: [
      RetrofitItem(
        id: 'thermostat',
        title: 'Smart Setbacks & Controls',
        subtitle:
            'Setbacks for AC/heat; explore smart thermostats (e.g., location tracking).',
        icon: Icons.thermostat_outlined,
        enabled: true, // Changed to true to enable this retrofit
      ),
    ],
  ),
  RetrofitSection(
    title: 'Heating (Conservation)',
    items: [
      RetrofitItem(
        id: 'heating_replace',
        title: 'Replace with More Efficient System',
        subtitle: 'See Replace for options.',
        icon: Icons.fireplace,
        enabled: false,
      ),
      RetrofitItem(
        id: 'heating_space_heaters',
        title: 'Reduce Space Heater Use',
        subtitle: 'Assess necessity; reduce if possible.',
        icon: Icons.fireplace,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Air Conditioning',
    items: [
      RetrofitItem(
        id: 'ac_replace',
        title: 'Replace Central/Window AC',
        subtitle: 'See Replace module for details.',
        icon: Icons.ac_unit_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'ac_maintenance',
        title: 'Annual Maintenance & Reminders',
        subtitle: 'Filters, coils, refrigerant checks.',
        icon: Icons.build_circle_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'ac_window_insulation',
        title: 'Window AC Insulation',
        subtitle: 'Seal gaps around window AC units.',
        icon: Icons.window_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'ac_night_vent',
        title: 'Nighttime Ventilation',
        subtitle: 'Whole-house or room-level night flushing.',
        icon: Icons.nights_stay_outlined,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Refrigerator',
    items: [
      RetrofitItem(
        id: 'fridge_replace',
        title: 'Replace Refrigerator',
        subtitle: 'Upgrade to efficient model.',
        icon: Icons.kitchen_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'fridge_reduce_units',
        title: 'Reduce Number of Fridges/Freezers',
        subtitle: 'Consolidate to cut standby and runtime.',
        icon: Icons.kitchen_outlined,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Dish Washer',
    items: [
      RetrofitItem(
        id: 'dw_replace',
        title: 'Replace Dishwasher',
        subtitle: 'Higher efficiency models.',
        icon: Icons.cleaning_services,
        enabled: false,
      ),
      RetrofitItem(
        id: 'dw_use_better',
        title: 'Use Dishwasher More Efficiently',
        subtitle: 'Full loads; eco modes; air-dry.',
        icon: Icons.cleaning_services,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Clothes Washing / Drying',
    items: [
      RetrofitItem(
        id: 'washer_replace',
        title: 'Replace Washer/Dryer',
        subtitle: 'Efficient washer; heat-pump dryer.',
        icon: Icons.local_laundry_service_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'laundry_use_better',
        title: 'Use More Efficiently',
        subtitle:
            'Cold water; auto humidity; hang drying; vent/drain maintenance.',
        icon: Icons.local_laundry_service_outlined,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Electrical Consumption / Plans',
    items: [
      RetrofitItem(
        id: 'tou_pricing',
        title: 'Time-of-Use / Demand Response',
        subtitle: 'Pricing education & enrollment.',
        icon: Icons.bolt_outlined,
        enabled: false,
      ),
      RetrofitItem(
        id: 'green_supply',
        title: 'Green Electricity Suppliers',
        subtitle: 'Opt-in to cleaner supply if available.',
        icon: Icons.eco_outlined,
        enabled: false,
      ),
    ],
  ),
  RetrofitSection(
    title: 'Other EEMs',
    items: [
      RetrofitItem(
        id: 'other_eems',
        title: 'Additional Measures',
        subtitle:
            'Spreadsheet has more items; requires extra questions to assess relevance.',
        icon: Icons.more_horiz,
        enabled: false,
      ),
    ],
  ),
];

/// The RetrofitsTab widget displays a list of available energy-saving retrofits,
/// grouped by section.
class RetrofitsTab extends ConsumerWidget {
  const RetrofitsTab({super.key});

  /// Handles tap events on a [RetrofitItem].
  /// Navigates to the corresponding page if the item is enabled.
  void _onTapItem(BuildContext context, RetrofitItem item) {
    if (!item.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} is coming soon')),
      );
      return;
    }
    switch (item.id) {
      case 'leakage':
        context.push('/leakage/dashboard');
        break;
      // Added navigation for new retrofit items
      case 'lighting_led':
        context.push('/retrofits/led');
        break;
      case 'thermostat':
        context.push('/retrofits/thermostat');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No route defined for "${item.title}"')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically build the list of widgets from the static catalog.
    final children = <Widget>[];
    for (final section in kRetrofitSections) {
      // Add a compact header for each section.
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(section.title, style: Theme.of(context).textTheme.titleSmall),
      ));
      // Add a card for each item within the section.
      for (final it in section.items) {
        children.add(_RetrofitItemCard(item: it, onTap: () => _onTapItem(context, it)));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: children,
    );
  }
}

/// A private widget to display a single [RetrofitItem] in a compact card.
class _RetrofitItemCard extends StatelessWidget {
  final RetrofitItem item;
  final VoidCallback onTap;
  const _RetrofitItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Uses a dense ListTile for a more compact appearance.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          leading: Icon(item.icon, size: 22),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: item.subtitle != null
              ? Text(item.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis)
              : null,
          trailing: item.enabled ? const Icon(Icons.chevron_right) : null,
          enabled: item.enabled,
          onTap: onTap,
        ),
      ),
    );
  }
}