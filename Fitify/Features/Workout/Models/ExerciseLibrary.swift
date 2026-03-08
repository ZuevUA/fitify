//
//  ExerciseLibrary.swift
//  Fitify
//
//  Complete exercise database with templates
//

import Foundation

// MARK: - Enums for Exercise Library

enum ExMuscleGroup: String, CaseIterable, Codable {
    case chest = "Груди"
    case back = "Спина"
    case shoulders = "Плечі"
    case biceps = "Біцепс"
    case triceps = "Трицепс"
    case legs = "Ноги"
    case glutes = "Сідниці"
    case abs = "Прес"
    case calves = "Ікри"
    case forearms = "Передпліччя"
}

enum ExEquipment: String, CaseIterable, Codable {
    case barbell = "Штанга"
    case dumbbell = "Гантелі"
    case cable = "Блок"
    case machine = "Тренажер"
    case bodyweight = "Власна вага"
    case any = "Будь-яке"
}

enum ExType: String, Codable {
    case compound = "compound"
    case isolation = "isolation"
}

// MARK: - Exercise Template

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let nameEn: String
    let muscleGroup: ExMuscleGroup
    let type: ExType
    let equipment: ExEquipment
    let defaultSets: Int
    let defaultRepsMin: Int
    let defaultRepsMax: Int
    let defaultRir: Int
    let defaultRestSeconds: Int
    let notes: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExerciseTemplate, rhs: ExerciseTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Exercise Library

struct ExerciseLibrary {

    static let all: [ExerciseTemplate] = chest + back + shoulders + legs + biceps + triceps + glutes + abs + calves

    // MARK: - ГРУДИ (8 exercises)
    static let chest: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Жим штанги лежачи",
            nameEn: "Barbell Bench Press",
            muscleGroup: .chest,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 6,
            defaultRepsMax: 10,
            defaultRir: 2,
            defaultRestSeconds: 180,
            notes: "Головна компаунд вправа на груди"
        ),
        ExerciseTemplate(
            name: "Жим на нахиленій лаві",
            nameEn: "Incline Bench Press",
            muscleGroup: .chest,
            type: .compound,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 150,
            notes: "Кут 30-45°, акцент на верхні груди"
        ),
        ExerciseTemplate(
            name: "Жим гантелей лежачи",
            nameEn: "Dumbbell Bench Press",
            muscleGroup: .chest,
            type: .compound,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Більший ROM ніж зі штангою"
        ),
        ExerciseTemplate(
            name: "Зведення в блоці",
            nameEn: "Cable Fly",
            muscleGroup: .chest,
            type: .isolation,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Пікове скорочення в кінці руху"
        ),
        ExerciseTemplate(
            name: "Віджимання на брусах",
            nameEn: "Dips",
            muscleGroup: .chest,
            type: .compound,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 120,
            notes: "Нахил вперед для акценту на груди"
        ),
        ExerciseTemplate(
            name: "Жим в тренажері Сміта",
            nameEn: "Smith Machine Press",
            muscleGroup: .chest,
            type: .compound,
            equipment: .machine,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Безпечний варіант без страхуючого"
        ),
        ExerciseTemplate(
            name: "Пулловер з гантеллю",
            nameEn: "Dumbbell Pullover",
            muscleGroup: .chest,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 15,
            defaultRir: 2,
            defaultRestSeconds: 90,
            notes: "Розтяжка грудей і широчайших"
        ),
        ExerciseTemplate(
            name: "Віджимання",
            nameEn: "Push-Up",
            muscleGroup: .chest,
            type: .compound,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 15,
            defaultRepsMax: 25,
            defaultRir: 2,
            defaultRestSeconds: 60,
            notes: "Можна з обтяженням у рюкзаку"
        ),
    ]

    // MARK: - СПИНА (8 exercises)
    static let back: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Станова тяга",
            nameEn: "Deadlift",
            muscleGroup: .back,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 4,
            defaultRepsMax: 6,
            defaultRir: 3,
            defaultRestSeconds: 240,
            notes: "Головна вправа. Не заокруглюй спину"
        ),
        ExerciseTemplate(
            name: "Тяга штанги в нахилі",
            nameEn: "Barbell Row",
            muscleGroup: .back,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 6,
            defaultRepsMax: 10,
            defaultRir: 2,
            defaultRestSeconds: 180,
            notes: "Лікті до стегон, не до плечей"
        ),
        ExerciseTemplate(
            name: "Підтягування",
            nameEn: "Pull-Up",
            muscleGroup: .back,
            type: .compound,
            equipment: .bodyweight,
            defaultSets: 4,
            defaultRepsMin: 6,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 150,
            notes: "Найкраща вправа для ширини спини"
        ),
        ExerciseTemplate(
            name: "Тяга верхнього блоку",
            nameEn: "Lat Pulldown",
            muscleGroup: .back,
            type: .compound,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Альтернатива підтягуванням"
        ),
        ExerciseTemplate(
            name: "Тяга нижнього блоку",
            nameEn: "Cable Row",
            muscleGroup: .back,
            type: .compound,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Зводь лопатки в кінці руху"
        ),
        ExerciseTemplate(
            name: "Тяга гантелі однією рукою",
            nameEn: "Single Arm Row",
            muscleGroup: .back,
            type: .compound,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Опирайся рукою на лаву"
        ),
        ExerciseTemplate(
            name: "Гіперекстензія",
            nameEn: "Back Extension",
            muscleGroup: .back,
            type: .isolation,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 2,
            defaultRestSeconds: 90,
            notes: "Для еректорів хребта і сідниць"
        ),
        ExerciseTemplate(
            name: "Тяга Т-грифу",
            nameEn: "T-Bar Row",
            muscleGroup: .back,
            type: .compound,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 150,
            notes: "Великий ROM, акцент на товщину"
        ),
    ]

    // MARK: - ПЛЕЧІ (7 exercises)
    static let shoulders: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Жим штанги стоячи",
            nameEn: "Overhead Press",
            muscleGroup: .shoulders,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 6,
            defaultRepsMax: 10,
            defaultRir: 2,
            defaultRestSeconds: 180,
            notes: "Головна вправа на плечі"
        ),
        ExerciseTemplate(
            name: "Жим гантелей сидячи",
            nameEn: "Dumbbell Shoulder Press",
            muscleGroup: .shoulders,
            type: .compound,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Більший ROM ніж зі штангою"
        ),
        ExerciseTemplate(
            name: "Розведення в сторони",
            nameEn: "Lateral Raise",
            muscleGroup: .shoulders,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 4,
            defaultRepsMin: 15,
            defaultRepsMax: 25,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Ключова вправа для ширини плечей"
        ),
        ExerciseTemplate(
            name: "Розведення в блоці",
            nameEn: "Cable Lateral Raise",
            muscleGroup: .shoulders,
            type: .isolation,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 15,
            defaultRepsMax: 25,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Постійне навантаження на м'яз"
        ),
        ExerciseTemplate(
            name: "Зворотні розведення",
            nameEn: "Rear Delt Fly",
            muscleGroup: .shoulders,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 15,
            defaultRepsMax: 25,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Задні дельти — часто відстають"
        ),
        ExerciseTemplate(
            name: "Тяга до підборіддя",
            nameEn: "Upright Row",
            muscleGroup: .shoulders,
            type: .compound,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 2,
            defaultRestSeconds: 90,
            notes: "Широкий хват для плечей"
        ),
        ExerciseTemplate(
            name: "Підйом перед собою",
            nameEn: "Front Raise",
            muscleGroup: .shoulders,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Передні дельти"
        ),
    ]

    // MARK: - НОГИ (8 exercises)
    static let legs: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Присідання зі штангою",
            nameEn: "Barbell Squat",
            muscleGroup: .legs,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 6,
            defaultRepsMax: 10,
            defaultRir: 2,
            defaultRestSeconds: 210,
            notes: "Коліна вздовж носків, спина пряма"
        ),
        ExerciseTemplate(
            name: "Жим ногами",
            nameEn: "Leg Press",
            muscleGroup: .legs,
            type: .compound,
            equipment: .machine,
            defaultSets: 4,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 150,
            notes: "Безпечна альтернатива присіданням"
        ),
        ExerciseTemplate(
            name: "Румунська тяга",
            nameEn: "Romanian Deadlift",
            muscleGroup: .legs,
            type: .compound,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 150,
            notes: "Акцент на задню поверхню стегна"
        ),
        ExerciseTemplate(
            name: "Розгинання ніг",
            nameEn: "Leg Extension",
            muscleGroup: .legs,
            type: .isolation,
            equipment: .machine,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Ізоляція квадрицепсів"
        ),
        ExerciseTemplate(
            name: "Згинання ніг лежачи",
            nameEn: "Lying Leg Curl",
            muscleGroup: .legs,
            type: .isolation,
            equipment: .machine,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Ізоляція задньої поверхні"
        ),
        ExerciseTemplate(
            name: "Випади з гантелями",
            nameEn: "Dumbbell Lunges",
            muscleGroup: .legs,
            type: .compound,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 2,
            defaultRestSeconds: 120,
            notes: "По 10-15 на кожну ногу"
        ),
        ExerciseTemplate(
            name: "Гак-присідання",
            nameEn: "Hack Squat",
            muscleGroup: .legs,
            type: .compound,
            equipment: .machine,
            defaultSets: 4,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 150,
            notes: "Вузька постановка — більше квадрицепсів"
        ),
        ExerciseTemplate(
            name: "Болгарські випади",
            nameEn: "Bulgarian Split Squat",
            muscleGroup: .legs,
            type: .compound,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 120,
            notes: "Задня нога на лаві"
        ),
    ]

    // MARK: - БІЦЕПС (5 exercises)
    static let biceps: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Підйом штанги на біцепс",
            nameEn: "Barbell Curl",
            muscleGroup: .biceps,
            type: .isolation,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Ліктями до тулуба"
        ),
        ExerciseTemplate(
            name: "Молоткові згинання",
            nameEn: "Hammer Curl",
            muscleGroup: .biceps,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Нейтральний хват — плечовий м'яз"
        ),
        ExerciseTemplate(
            name: "Згинання в блоці",
            nameEn: "Cable Curl",
            muscleGroup: .biceps,
            type: .isolation,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Постійне натяжіння"
        ),
        ExerciseTemplate(
            name: "Концентроване згинання",
            nameEn: "Concentration Curl",
            muscleGroup: .biceps,
            type: .isolation,
            equipment: .dumbbell,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Пік скорочення зверху"
        ),
        ExerciseTemplate(
            name: "Згинання на лаві Скотта",
            nameEn: "Scott Curl",
            muscleGroup: .biceps,
            type: .isolation,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Фіксований лікоть — чиста ізоляція"
        ),
    ]

    // MARK: - ТРИЦЕПС (4 exercises)
    static let triceps: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Французький жим",
            nameEn: "Skull Crusher",
            muscleGroup: .triceps,
            type: .isolation,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Довга голівка трицепса"
        ),
        ExerciseTemplate(
            name: "Розгинання в блоці",
            nameEn: "Cable Pushdown",
            muscleGroup: .triceps,
            type: .isolation,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Прямий або канатний гриф"
        ),
        ExerciseTemplate(
            name: "Жим вузьким хватом",
            nameEn: "Close Grip Bench Press",
            muscleGroup: .triceps,
            type: .compound,
            equipment: .barbell,
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            defaultRir: 2,
            defaultRestSeconds: 120,
            notes: "Хват трохи вужче плечей"
        ),
        ExerciseTemplate(
            name: "Віджимання на брусах (трицепс)",
            nameEn: "Tricep Dips",
            muscleGroup: .triceps,
            type: .compound,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 2,
            defaultRestSeconds: 90,
            notes: "Тулуб прямо — акцент на трицепс"
        ),
    ]

    // MARK: - СІДНИЦІ (3 exercises)
    static let glutes: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Ягідний місток зі штангою",
            nameEn: "Barbell Hip Thrust",
            muscleGroup: .glutes,
            type: .compound,
            equipment: .barbell,
            defaultSets: 4,
            defaultRepsMin: 10,
            defaultRepsMax: 15,
            defaultRir: 1,
            defaultRestSeconds: 120,
            notes: "Найкраща вправа для сідниць"
        ),
        ExerciseTemplate(
            name: "Зворотні гіперекстензії",
            nameEn: "Reverse Hyperextension",
            muscleGroup: .glutes,
            type: .isolation,
            equipment: .machine,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 90,
            notes: "Акцент на сідниці і задню поверхню"
        ),
        ExerciseTemplate(
            name: "Відведення ноги в блоці",
            nameEn: "Cable Kickback",
            muscleGroup: .glutes,
            type: .isolation,
            equipment: .cable,
            defaultSets: 3,
            defaultRepsMin: 15,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "По 15-20 на кожну ногу"
        ),
    ]

    // MARK: - ПРЕС (3 exercises)
    static let abs: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Скручування",
            nameEn: "Crunch",
            muscleGroup: .abs,
            type: .isolation,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 15,
            defaultRepsMax: 25,
            defaultRir: 2,
            defaultRestSeconds: 60,
            notes: "Підборіддя вгору, не тягни шию"
        ),
        ExerciseTemplate(
            name: "Планка",
            nameEn: "Plank",
            muscleGroup: .abs,
            type: .isolation,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 30,
            defaultRepsMax: 60,
            defaultRir: 2,
            defaultRestSeconds: 60,
            notes: "В секундах, не в повтореннях"
        ),
        ExerciseTemplate(
            name: "Підйом ніг лежачи",
            nameEn: "Leg Raise",
            muscleGroup: .abs,
            type: .isolation,
            equipment: .bodyweight,
            defaultSets: 3,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 2,
            defaultRestSeconds: 60,
            notes: "Нижній прес"
        ),
    ]

    // MARK: - ІКРИ (1 exercise)
    static let calves: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "Підйом на носки стоячи",
            nameEn: "Standing Calf Raise",
            muscleGroup: .calves,
            type: .isolation,
            equipment: .machine,
            defaultSets: 4,
            defaultRepsMin: 12,
            defaultRepsMax: 20,
            defaultRir: 1,
            defaultRestSeconds: 60,
            notes: "Повна амплітуда, повільно вниз"
        ),
    ]

    // MARK: - Helper Methods

    static func exercises(for muscleGroup: ExMuscleGroup) -> [ExerciseTemplate] {
        all.filter { $0.muscleGroup == muscleGroup }
    }

    static func search(_ query: String) -> [ExerciseTemplate] {
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.nameEn.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Array Extension for unique

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension Array where Element == String {
    func unique() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
