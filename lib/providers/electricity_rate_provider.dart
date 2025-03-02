import 'package:flutter/material.dart';

class ElectricityRateProvider with ChangeNotifier {
  // KSEB Kerala domestic rates (as of 2024)
  final List<Map<String, dynamic>> _rates = [
    {'minUnits': 0, 'maxUnits': 50, 'ratePerUnit': 3.15},
    {'minUnits': 51, 'maxUnits': 100, 'ratePerUnit': 3.70},
    {'minUnits': 101, 'maxUnits': 150, 'ratePerUnit': 4.80},
    {'minUnits': 151, 'maxUnits': double.infinity, 'ratePerUnit': 6.90},
  ];

  List<Map<String, dynamic>> get rates => _rates;

  double calculateTotalCost(double totalUnits) {
    double totalCost = 0.0;
    double remainingUnits = totalUnits;

    for (var slab in _rates) {
      if (remainingUnits <= 0) break;

      // Convert minUnits and maxUnits to double for calculation
      double minUnits = slab['minUnits'].toDouble();
      double maxUnits = slab['maxUnits'] == double.infinity ? double.infinity : slab['maxUnits'].toDouble();
      double slabUnits = maxUnits == double.infinity
          ? remainingUnits
          : (maxUnits - minUnits + 1.0); // Ensure +1.0 keeps it as double
      double unitsInSlab = remainingUnits > slabUnits ? slabUnits : remainingUnits;
      totalCost += unitsInSlab * slab['ratePerUnit'];
      remainingUnits -= unitsInSlab;
    }

    return totalCost;
  }

  double getApplicableRate(double totalUnits) {
    for (var rate in _rates.reversed) {
      if (totalUnits >= rate['minUnits'].toDouble()) { // Convert to double for comparison
        return rate['ratePerUnit'];
      }
    }
    return _rates.first['ratePerUnit'];
  }
}