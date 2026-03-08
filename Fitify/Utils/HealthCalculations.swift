//
//  HealthCalculations.swift
//  Fitify
//

import Foundation

enum HealthCalculations {
    /// Calculates recovery score (0-100) based on health metrics
    /// Higher HRV, lower resting HR, better sleep = higher recovery
    static func calculateRecoveryScore(
        hrv: Double?,
        restingHeartRate: Double?,
        sleepDuration: TimeInterval?,
        sleepQuality: Double?
    ) -> Int {
        var score: Double = 50 // Base score

        // HRV contribution (higher is better)
        // Average HRV ranges: 20-40ms (poor), 40-60ms (normal), 60+ms (excellent)
        if let hrv = hrv {
            if hrv >= 60 {
                score += 20
            } else if hrv >= 40 {
                score += 10
            } else if hrv < 30 {
                score -= 10
            }
        }

        // Resting HR contribution (lower is better)
        // Average: 60-100bpm, athletes: 40-60bpm
        if let rhr = restingHeartRate {
            if rhr <= 55 {
                score += 15
            } else if rhr <= 65 {
                score += 8
            } else if rhr > 75 {
                score -= 10
            }
        }

        // Sleep duration contribution (7-9 hours optimal)
        if let sleepDuration = sleepDuration {
            let hours = sleepDuration / 3600
            if hours >= 7 && hours <= 9 {
                score += 15
            } else if hours >= 6 && hours < 7 {
                score += 5
            } else if hours < 6 {
                score -= 15
            } else if hours > 9 {
                score += 5 // Slightly less optimal but still good
            }
        }

        // Sleep quality contribution
        if let quality = sleepQuality {
            if quality >= 80 {
                score += 10
            } else if quality >= 60 {
                score += 5
            } else if quality < 50 {
                score -= 10
            }
        }

        return max(0, min(100, Int(score)))
    }

    /// Calculates stress level (0-100) based on health metrics
    /// Lower HRV, higher HR, poor sleep = higher stress
    static func calculateStressLevel(
        heartRate: Double?,
        hrv: Double?,
        restingHeartRate: Double?,
        sleepDuration: TimeInterval?
    ) -> Double {
        var stress: Double = 30 // Base stress level

        // HRV impact (lower HRV = higher stress)
        if let hrv = hrv {
            if hrv < 30 {
                stress += 25
            } else if hrv < 40 {
                stress += 15
            } else if hrv >= 60 {
                stress -= 15
            }
        }

        // Current HR vs Resting HR
        if let hr = heartRate, let rhr = restingHeartRate {
            let diff = hr - rhr
            if diff > 30 {
                stress += 20
            } else if diff > 20 {
                stress += 10
            }
        }

        // Sleep deprivation impact
        if let sleepDuration = sleepDuration {
            let hours = sleepDuration / 3600
            if hours < 5 {
                stress += 25
            } else if hours < 6 {
                stress += 15
            } else if hours < 7 {
                stress += 5
            }
        }

        return max(0, min(100, stress))
    }

    /// Assesses virus/illness risk based on health anomalies
    static func assessVirusRisk(
        bodyTemperature: Double?,
        restingHeartRate: Double?,
        baselineRestingHR: Double = 60,
        hrv: Double?,
        baselineHRV: Double = 45,
        oxygenSaturation: Double?
    ) -> RiskLevel {
        var riskScore = 0

        // Elevated temperature
        if let temp = bodyTemperature {
            if temp >= 38.0 {
                riskScore += 3
            } else if temp >= 37.5 {
                riskScore += 2
            } else if temp >= 37.2 {
                riskScore += 1
            }
        }

        // Elevated resting HR (10+ bpm above baseline)
        if let rhr = restingHeartRate {
            let elevation = rhr - baselineRestingHR
            if elevation >= 15 {
                riskScore += 2
            } else if elevation >= 10 {
                riskScore += 1
            }
        }

        // Decreased HRV (20%+ below baseline)
        if let hrv = hrv {
            let decrease = (baselineHRV - hrv) / baselineHRV
            if decrease >= 0.3 {
                riskScore += 2
            } else if decrease >= 0.2 {
                riskScore += 1
            }
        }

        // Low oxygen saturation
        if let o2 = oxygenSaturation {
            if o2 < 94 {
                riskScore += 3
            } else if o2 < 96 {
                riskScore += 1
            }
        }

        // Determine risk level
        if riskScore >= 5 {
            return .high
        } else if riskScore >= 2 {
            return .medium
        } else {
            return .low
        }
    }

    /// Calculates sleep quality score (0-100) based on sleep metrics
    static func calculateSleepQuality(
        totalSleep: TimeInterval,
        deepSleep: TimeInterval? = nil,
        remSleep: TimeInterval? = nil,
        awakenings: Int? = nil
    ) -> Double {
        guard totalSleep > 0 else { return 0 }

        var quality: Double = 50

        // Duration score
        let hours = totalSleep / 3600
        if hours >= 7 && hours <= 9 {
            quality += 25
        } else if hours >= 6 {
            quality += 15
        } else if hours < 5 {
            quality -= 20
        }

        // Deep sleep contribution (ideally 15-20% of total)
        if let deep = deepSleep {
            let deepPercent = deep / totalSleep * 100
            if deepPercent >= 15 && deepPercent <= 25 {
                quality += 15
            } else if deepPercent >= 10 {
                quality += 8
            }
        }

        // REM sleep contribution (ideally 20-25% of total)
        if let rem = remSleep {
            let remPercent = rem / totalSleep * 100
            if remPercent >= 20 && remPercent <= 25 {
                quality += 10
            } else if remPercent >= 15 {
                quality += 5
            }
        }

        // Awakenings penalty
        if let awakenings = awakenings {
            if awakenings == 0 {
                quality += 10
            } else if awakenings <= 2 {
                quality += 5
            } else if awakenings > 5 {
                quality -= 15
            }
        }

        return max(0, min(100, quality))
    }
}

// MARK: - Formatting Helpers

extension HealthCalculations {
    static func formatHeartRate(_ bpm: Double) -> String {
        "\(Int(bpm)) bpm"
    }

    static func formatHRV(_ ms: Double) -> String {
        "\(Int(ms)) ms"
    }

    static func formatTemperature(_ celsius: Double) -> String {
        String(format: "%.1f°C", celsius)
    }

    static func formatOxygenSaturation(_ percent: Double) -> String {
        "\(Int(percent))%"
    }

    static func formatSteps(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    static func formatEnergy(_ kcal: Double) -> String {
        "\(Int(kcal)) kcal"
    }

    static func formatSleepDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    static func formatRecoveryScore(_ score: Int) -> String {
        "\(score)%"
    }

    static func formatStressLevel(_ level: Double) -> String {
        "\(Int(level))%"
    }
}
