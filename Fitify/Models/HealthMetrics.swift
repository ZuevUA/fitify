//
//  HealthMetrics.swift
//  Fitify
//

import Foundation
import HealthKit

enum HealthMetricType: String, CaseIterable, Identifiable {
    case heartRate
    case heartRateVariability
    case restingHeartRate
    case bodyTemperature
    case oxygenSaturation
    case stepCount
    case activeEnergy
    case sleepAnalysis

    var id: String { rawValue }

    var healthKitIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        case .heartRate: return .heartRate
        case .heartRateVariability: return .heartRateVariabilitySDNN
        case .restingHeartRate: return .restingHeartRate
        case .bodyTemperature: return .bodyTemperature
        case .oxygenSaturation: return .oxygenSaturation
        case .stepCount: return .stepCount
        case .activeEnergy: return .activeEnergyBurned
        case .sleepAnalysis: return nil
        }
    }

    var categoryIdentifier: HKCategoryTypeIdentifier? {
        switch self {
        case .sleepAnalysis: return .sleepAnalysis
        default: return nil
        }
    }

    var unit: HKUnit {
        switch self {
        case .heartRate, .restingHeartRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariability:
            return .secondUnit(with: .milli)
        case .bodyTemperature:
            return .degreeCelsius()
        case .oxygenSaturation:
            return .percent()
        case .stepCount:
            return .count()
        case .activeEnergy:
            return .kilocalorie()
        case .sleepAnalysis:
            return .hour()
        }
    }

    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .heartRateVariability: return "HRV"
        case .restingHeartRate: return "Resting HR"
        case .bodyTemperature: return "Temperature"
        case .oxygenSaturation: return "Blood Oxygen"
        case .stepCount: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .sleepAnalysis: return "Sleep"
        }
    }

    var iconName: String {
        switch self {
        case .heartRate, .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .bodyTemperature: return "thermometer"
        case .oxygenSaturation: return "lungs.fill"
        case .stepCount: return "figure.walk"
        case .activeEnergy: return "flame.fill"
        case .sleepAnalysis: return "bed.double.fill"
        }
    }
}

enum RiskLevel: String, Codable {
    case low
    case medium
    case high

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}
