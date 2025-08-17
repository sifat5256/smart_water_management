import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static const String deviceId = "hridoy_esp32"; // Match your ESP32 device ID
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Get reference to device data
  static DatabaseReference get _deviceRef => _database.child('devices/$deviceId');
  static Future<void> controlPump({required bool turnOn}) async {
    try {
      // Update both force_on and force_off to avoid conflicts
      await _deviceRef.child('control').update({
        'force_on': turnOn,
        'force_off': !turnOn,
      });
    } catch (e) {
      print('Error controlling pump: $e');
      rethrow;
    }
  }

  // Enhanced enableAutoMode method
  static Future<void> enableAutoMode() async {
    try {
      await _deviceRef.child('control').update({
        'force_on': false,
        'force_off': false,
      });
    } catch (e) {
      print('Error enabling auto mode: $e');
      rethrow;
    }
  }
  static Stream<bool> getPumpStatus() {
    return _deviceRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final control = data['control'] as Map<dynamic, dynamic>? ?? {};
      final telemetry = data['telemetry'] as Map<dynamic, dynamic>? ?? {};

      // Priority 1: Manual control flags
      if (control['force_on'] == true) return true;
      if (control['force_off'] == true) return false;

      // Priority 2: Telemetry pump state (actual pump state)
      if (telemetry['pump'] != null) {
        return telemetry['pump'] as bool;
      }

      // Default fallback
      return false;
    });
  }

  // Enhanced pump status listener
  // static Stream<bool> getPumpStatus() {
  //   return _deviceRef.child('control').onValue.map((event) {
  //     final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
  //
  //     // Prioritize force_on/force_off over telemetry
  //     if (data['force_on'] == true) return true;
  //     if (data['force_off'] == true) return false;
  //
  //     // Fallback to telemetry if no control commands
  //     final telemetry = (event.snapshot.parent?.child('telemetry/pump').value as bool?) ?? false;
  //     return telemetry;
  //   });
  // }
  // Control pump state
  // static Future<void> controlPump({required bool turnOn}) async {
  //   try {
  //     if (turnOn) {
  //       await _deviceRef.child('control/force_on').set(true);
  //       await _deviceRef.child('control/force_off').set(false);
  //     } else {
  //       await _deviceRef.child('control/force_on').set(false);
  //       await _deviceRef.child('control/force_off').set(true);
  //     }
  //   } catch (e) {
  //     print('Error controlling pump: $e');
  //     rethrow;
  //   }
  // }

  // Enable automatic pump control (disable manual override)
  // static Future<void> enableAutoMode() async {
  //   try {
  //     await _deviceRef.child('control/force_on').set(false);
  //     await _deviceRef.child('control/force_off').set(false);
  //   } catch (e) {
  //     print('Error enabling auto mode: $e');
  //     rethrow;
  //   }
  // }

  // Listen to pump status changes
  // static Stream<bool> getPumpStatus() {
  //   return _deviceRef.onValue.map((event) {
  //     final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
  //     final telemetry = data['telemetry'] as Map? ?? {};
  //     final control = data['control'] as Map? ?? {};
  //
  //     // Prefer telemetry if ESP32 reports it
  //     if (telemetry['pump'] != null) {
  //       return telemetry['pump'] as bool? ?? false;
  //     }
  //
  //     // Fallback: deduce from control flags
  //     if (control['force_on'] == true) return true;
  //     if (control['force_off'] == true) return false;
  //
  //     return false;
  //   });
  // }


  // Listen to water level changes
  static Stream<int> getWaterLevel() {
    return _deviceRef.child('telemetry/level/percent').onValue.map((event) {
      return event.snapshot.value as int? ?? 0;
    });
  }

  // Listen to temperature changes - FIXED PATH
  static Stream<double> getTemperature() {
    return _deviceRef.child('telemetry/temperature/c').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return 0.0;

      try {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      } catch (e) {
        print('Temperature parsing error: $e');
        return 0.0;
      }
    });
  }

  // Listen to turbidity changes - FIXED PATH
  static Stream<Map<String, dynamic>> getTurbidity() {
    return _deviceRef.child('telemetry').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      try {
        // Try to get from nested turbidity object first
        final turbidityObj = data['turbidity'] as Map<dynamic, dynamic>?;
        double ntuValue = 0.0;
        String statusValue = 'UNKNOWN';

        if (turbidityObj != null) {
          ntuValue = (turbidityObj['ntu'] as num?)?.toDouble() ?? 0.0;
          statusValue = turbidityObj['status']?.toString() ?? 'UNKNOWN';
        }

        // If nested object gives 0, try the separate turbidity_ntu field
        if (ntuValue == 0.0) {
          ntuValue = (data['turbidity_ntu'] as num?)?.toDouble() ?? 0.0;
        }

        final turbidityData = {
          'ntu': ntuValue,
          'status': statusValue,
        };

        print('Turbidity raw data: $data');
        print('Turbidity parsed: $turbidityData');

        return turbidityData;
      } catch (e) {
        print('Turbidity parsing error: $e');
        return {'ntu': 0.0, 'status': 'UNKNOWN'};
      }
    });
  }

  // Listen to flow sensor 1 data - FIXED PATH
  static Stream<Map<String, dynamic>> getFlow1Data() {
    return _deviceRef.child('telemetry/flow1').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'lpm': (data['lpm'] as num?)?.toDouble() ?? 0.0,
        'total_liters': (data['total_liters'] as num?)?.toDouble() ?? 0.0,
        'total_bill': (data['total_bill'] as num?)?.toDouble() ?? 0.0,
        'price_per_liter': (data['price_per_liter'] as num?)?.toDouble() ?? 1.5,
      };
    });
  }

  // Listen to flow sensor 2 data - FIXED PATH
  static Stream<Map<String, dynamic>> getFlow2Data() {
    return _deviceRef.child('telemetry/flow2').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'lpm': (data['lpm'] as num?)?.toDouble() ?? 0.0,
        'total_liters': (data['total_liters'] as num?)?.toDouble() ?? 0.0,
        'total_bill': (data['total_bill'] as num?)?.toDouble() ?? 0.0,
        'price_per_liter': (data['price_per_liter'] as num?)?.toDouble() ?? 2.0,
      };
    });
  }

  // Reset usage for flow sensor 1
  static Future<void> resetFlow1Usage() async {
    try {
      await _deviceRef.child('control/reset_usage1').set(true);
    } catch (e) {
      print('Error resetting flow1 usage: $e');
      rethrow;
    }
  }

  // Reset usage for flow sensor 2
  static Future<void> resetFlow2Usage() async {
    try {
      await _deviceRef.child('control/reset_usage2').set(true);
    } catch (e) {
      print('Error resetting flow2 usage: $e');
      rethrow;
    }
  }

  // Update configuration
  static Future<void> updateConfig({
    double? tankHeightCm,
    double? pulsesPerLiter1,
    double? pulsesPerLiter2,
    double? pricePerLiter1,
    double? pricePerLiter2,
    int? lowLevelPercent,
    int? highLevelPercent,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (tankHeightCm != null) updates['tank_height_cm'] = tankHeightCm;
      if (pulsesPerLiter1 != null) updates['pulses_per_liter1'] = pulsesPerLiter1;
      if (pulsesPerLiter2 != null) updates['pulses_per_liter2'] = pulsesPerLiter2;
      if (pricePerLiter1 != null) updates['price_per_liter1'] = pricePerLiter1;
      if (pricePerLiter2 != null) updates['price_per_liter2'] = pricePerLiter2;
      if (lowLevelPercent != null) updates['low_level_percent'] = lowLevelPercent;
      if (highLevelPercent != null) updates['high_level_percent'] = highLevelPercent;

      if (updates.isNotEmpty) {
        await _deviceRef.child('config').update(updates);
      }
    } catch (e) {
      print('Error updating config: $e');
      rethrow;
    }
  }
}