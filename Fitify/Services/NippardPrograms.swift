//
//  NippardPrograms.swift
//  Fitify
//
//  Jeff Nippard evidence-based program templates
//

import Foundation

// MARK: - Template Models

struct NippardProgramTemplate {
    let id: String
    let name: String
    let nameUk: String
    let targetLevels: [String]  // beginner, intermediate, advanced
    let frequencyDays: Int
    let maxSessionMinutes: Int
    let goal: String
    let description: String
    let workoutDays: [NippardDayTemplate]
}

struct NippardDayTemplate {
    let dayNumber: Int
    let workoutType: String
    let exercises: [NippardExerciseTemplate]
}

struct NippardExerciseTemplate {
    let name: String
    let nameEn: String
    let sets: Int
    let repsMin: Int
    let repsMax: Int
    let rir: Int
    let restSeconds: Int
    let muscleGroup: String
    let notes: String
}

// MARK: - All Programs

struct NippardPrograms {

    static let all: [NippardProgramTemplate] = [
        minimalist2Day,
        fundamentals3Day,
        minMax4Day,
        transformation5Day,
        upperLower6Day
    ]

    // MARK: - 1. Minimalist 2-Day Full Body

    static let minimalist2Day = NippardProgramTemplate(
        id: "minimalist-2day",
        name: "Minimalist 2-Day",
        nameUk: "Мінімалістична 2-денна",
        targetLevels: ["beginner", "intermediate"],
        frequencyDays: 2,
        maxSessionMinutes: 45,
        goal: "maintenance",
        description: "Ефективна програма для зайнятих людей. Максимальний результат за мінімум часу.",
        workoutDays: [
            NippardDayTemplate(
                dayNumber: 1,
                workoutType: "Full Body A",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Присідання зі штангою",
                        nameEn: "Barbell Back Squat",
                        sets: 3, repsMin: 6, repsMax: 8, rir: 2,
                        restSeconds: 180, muscleGroup: "quads",
                        notes: "Глибокий присід, контроль у нижній точці"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей на горизонтальній лаві",
                        nameEn: "Flat Dumbbell Press",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Повна амплітуда, контрольоване опускання"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга штанги в нахилі",
                        nameEn: "Barbell Row",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Тримай спину рівно, тягни до пупка"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга",
                        nameEn: "Romanian Deadlift",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "hamstrings",
                        notes: "Відчуй розтяжку біцепса стегна"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей сидячи",
                        nameEn: "Seated Dumbbell Press",
                        sets: 2, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 90, muscleGroup: "shoulders",
                        notes: "Не замикай лікті у верхній точці"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 2,
                workoutType: "Rest",
                exercises: []
            ),
            NippardDayTemplate(
                dayNumber: 3,
                workoutType: "Rest",
                exercises: []
            ),
            NippardDayTemplate(
                dayNumber: 4,
                workoutType: "Full Body B",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Станова тяга",
                        nameEn: "Conventional Deadlift",
                        sets: 3, repsMin: 5, repsMax: 8, rir: 2,
                        restSeconds: 180, muscleGroup: "back",
                        notes: "Тримай спину нейтрально, штанга близько до тіла"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим штанги на нахиленій лаві",
                        nameEn: "Incline Barbell Press",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Кут 30-45 градусів"
                    ),
                    NippardExerciseTemplate(
                        name: "Підтягування",
                        nameEn: "Pull-ups",
                        sets: 3, repsMin: 6, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Повна амплітуда, без розгойдування"
                    ),
                    NippardExerciseTemplate(
                        name: "Болгарські випади",
                        nameEn: "Bulgarian Split Squat",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "quads",
                        notes: "Контролюй баланс, коліно не виходить за носок"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Легка вага, контроль у верхній точці"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 5, workoutType: "Rest", exercises: []),
            NippardDayTemplate(dayNumber: 6, workoutType: "Rest", exercises: []),
            NippardDayTemplate(dayNumber: 7, workoutType: "Rest", exercises: [])
        ]
    )

    // MARK: - 2. Fundamentals 3-Day Full Body

    static let fundamentals3Day = NippardProgramTemplate(
        id: "fundamentals-3day",
        name: "Fundamentals 3-Day",
        nameUk: "Основи гіпертрофії 3-денна",
        targetLevels: ["beginner"],
        frequencyDays: 3,
        maxSessionMinutes: 60,
        goal: "buildMuscle",
        description: "Ідеальний старт для новачків. Базові рухи для побудови фундаменту.",
        workoutDays: [
            NippardDayTemplate(
                dayNumber: 1,
                workoutType: "Full Body A",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Присідання зі штангою",
                        nameEn: "Barbell Squat",
                        sets: 3, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 150, muscleGroup: "quads",
                        notes: "Основа для ніг. Глибина до паралелі."
                    ),
                    NippardExerciseTemplate(
                        name: "Жим штанги лежачи",
                        nameEn: "Bench Press",
                        sets: 3, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 150, muscleGroup: "chest",
                        notes: "Лопатки зведені, невеликий прогин у попереку"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга верхнього блоку",
                        nameEn: "Lat Pulldown",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Тягни ліктями вниз, не назад"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей сидячи",
                        nameEn: "Seated DB Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "shoulders",
                        notes: "Не замикай лікті повністю"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання рук зі штангою",
                        nameEn: "Barbell Curl",
                        sets: 2, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Без читінгу, контроль негативної фази"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 2, workoutType: "Rest", exercises: []),
            NippardDayTemplate(
                dayNumber: 3,
                workoutType: "Full Body B",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Румунська тяга",
                        nameEn: "Romanian Deadlift",
                        sets: 3, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 150, muscleGroup: "hamstrings",
                        notes: "Штанга ковзає по стегнах"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей на нахиленій лаві",
                        nameEn: "Incline DB Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Кут 30 градусів для верхніх грудей"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга гантелі в нахилі",
                        nameEn: "Single Arm DB Row",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Тягни до стегна, не до грудей"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Контроль важливіший за вагу"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання рук на блоці",
                        nameEn: "Tricep Pushdown",
                        sets: 2, repsMin: 12, repsMax: 15, rir: 2,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Лікті притиснуті до тіла"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 4, workoutType: "Rest", exercises: []),
            NippardDayTemplate(
                dayNumber: 5,
                workoutType: "Full Body C",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим ногами",
                        nameEn: "Leg Press",
                        sets: 3, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Ноги на ширині плечей, коліна назовні"
                    ),
                    NippardExerciseTemplate(
                        name: "Віджимання на брусах",
                        nameEn: "Dips",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Нахил вперед для грудей"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга нижнього блоку",
                        nameEn: "Seated Cable Row",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Випинай груди, зводь лопатки"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки стоячи",
                        nameEn: "Standing Calf Raise",
                        sets: 3, repsMin: 12, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Повна амплітуда, пауза вгорі"
                    ),
                    NippardExerciseTemplate(
                        name: "Планка",
                        nameEn: "Plank",
                        sets: 3, repsMin: 30, repsMax: 60, rir: 1,
                        restSeconds: 60, muscleGroup: "abs",
                        notes: "Секунди. Тримай тіло рівно."
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 6, workoutType: "Rest", exercises: []),
            NippardDayTemplate(dayNumber: 7, workoutType: "Rest", exercises: [])
        ]
    )

    // MARK: - 3. Min-Max 4-Day Upper/Lower

    static let minMax4Day = NippardProgramTemplate(
        id: "minmax-4day",
        name: "Min-Max 4-Day",
        nameUk: "Мін-Макс 4-денна",
        targetLevels: ["intermediate", "advanced"],
        frequencyDays: 4,
        maxSessionMinutes: 45,
        goal: "buildMuscle",
        description: "Мінімальний час, максимальна інтенсивність. Ефективність перш за все.",
        workoutDays: [
            NippardDayTemplate(
                dayNumber: 1,
                workoutType: "Upper Body A",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим гантелей на нахиленій лаві",
                        nameEn: "Incline Dumbbell Press",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 1,
                        restSeconds: 150, muscleGroup: "chest",
                        notes: "Контрольоване опускання 3 секунди"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга нижнього блоку",
                        nameEn: "Cable Row",
                        sets: 3, repsMin: 10, repsMax: 15, rir: 1,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Відводь лікті до стегон"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей сидячи",
                        nameEn: "Seated DB Shoulder Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 1,
                        restSeconds: 90, muscleGroup: "shoulders",
                        notes: "Нейтральний хват для безпеки плечей"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей на біцепс",
                        nameEn: "Dumbbell Curl",
                        sets: 2, repsMin: 10, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Супінація у верхній точці"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання рук над головою",
                        nameEn: "Overhead Tricep Extension",
                        sets: 2, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Лікті направлені вперед"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 2,
                workoutType: "Lower Body A",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Присідання зі штангою",
                        nameEn: "Barbell Back Squat",
                        sets: 3, repsMin: 6, repsMax: 8, rir: 1,
                        restSeconds: 180, muscleGroup: "quads",
                        notes: "Глибокий присід, вибухова фаза вгору"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга",
                        nameEn: "Romanian Deadlift",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 1,
                        restSeconds: 150, muscleGroup: "hamstrings",
                        notes: "Розтяжка біцепса стегна"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання ніг у тренажері",
                        nameEn: "Leg Extension",
                        sets: 2, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "quads",
                        notes: "Пауза у верхній точці"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання ніг лежачи",
                        nameEn: "Lying Leg Curl",
                        sets: 2, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "Контроль через всю амплітуду"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки сидячи",
                        nameEn: "Seated Calf Raise",
                        sets: 3, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Повільне опускання"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 3, workoutType: "Rest", exercises: []),
            NippardDayTemplate(
                dayNumber: 4,
                workoutType: "Upper Body B",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Підтягування широким хватом",
                        nameEn: "Wide Grip Pull-ups",
                        sets: 3, repsMin: 6, repsMax: 10, rir: 1,
                        restSeconds: 150, muscleGroup: "back",
                        notes: "Широкий хват, тягни грудьми до перекладини"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим штанги лежачи",
                        nameEn: "Flat Bench Press",
                        sets: 3, repsMin: 6, repsMax: 10, rir: 1,
                        restSeconds: 150, muscleGroup: "chest",
                        notes: "Хват трохи ширше плечей"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Легка вага, ідеальна техніка"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга на задні дельти",
                        nameEn: "Face Pull",
                        sets: 3, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Зовнішня ротація в кінці"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання рук на верхньому блоці",
                        nameEn: "Cable Curl",
                        sets: 2, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Постійне напруження"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 5,
                workoutType: "Lower Body B",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Станова тяга",
                        nameEn: "Conventional Deadlift",
                        sets: 3, repsMin: 5, repsMax: 8, rir: 1,
                        restSeconds: 180, muscleGroup: "back",
                        notes: "Один важкий підхід, два легших"
                    ),
                    NippardExerciseTemplate(
                        name: "Болгарські випади",
                        nameEn: "Bulgarian Split Squat",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 1,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Фокус на квадрицепс"
                    ),
                    NippardExerciseTemplate(
                        name: "Гіперекстензія",
                        nameEn: "Back Extension",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "З затримкою у верхній точці"
                    ),
                    NippardExerciseTemplate(
                        name: "Приведення ніг у тренажері",
                        nameEn: "Hip Adductor Machine",
                        sets: 2, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "adductors",
                        notes: "Контрольований рух"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки стоячи",
                        nameEn: "Standing Calf Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Пауза у верхній точці"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 6, workoutType: "Rest", exercises: []),
            NippardDayTemplate(dayNumber: 7, workoutType: "Rest", exercises: [])
        ]
    )

    // MARK: - 4. Bodybuilding Transformation 5-Day (Upper/Lower + PPL)

    static let transformation5Day = NippardProgramTemplate(
        id: "transformation-5day",
        name: "Bodybuilding 5-Day",
        nameUk: "Трансформація 5-денна",
        targetLevels: ["intermediate", "advanced"],
        frequencyDays: 5,
        maxSessionMinutes: 75,
        goal: "buildMuscle",
        description: "Upper/Lower + PPL гібрид. Оптимальний об'єм для максимального росту.",
        workoutDays: [
            // День 1: Upper Body
            NippardDayTemplate(
                dayNumber: 1,
                workoutType: "Upper",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим штанги лежачи",
                        nameEn: "Barbell Bench Press",
                        sets: 4, repsMin: 6, repsMax: 8, rir: 2,
                        restSeconds: 180, muscleGroup: "chest",
                        notes: "Головна компаунд вправа"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга штанги в нахилі",
                        nameEn: "Barbell Row",
                        sets: 4, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 150, muscleGroup: "back",
                        notes: "Баланс push/pull"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей сидячи",
                        nameEn: "Seated DB Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "shoulders",
                        notes: "Повна амплітуда"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга верхнього блоку",
                        nameEn: "Lat Pulldown",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Широкий хват"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Контроль у верхній точці"
                    )
                ]
            ),
            // День 2: Lower Body
            NippardDayTemplate(
                dayNumber: 2,
                workoutType: "Lower",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Присідання зі штангою",
                        nameEn: "Barbell Squat",
                        sets: 4, repsMin: 6, repsMax: 8, rir: 2,
                        restSeconds: 180, muscleGroup: "quads",
                        notes: "Глибокий присід"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга",
                        nameEn: "Romanian Deadlift",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 150, muscleGroup: "hamstrings",
                        notes: "Розтяжка біцепса стегна"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим ногами",
                        nameEn: "Leg Press",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 2,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Ноги вузько для квадрицепсу"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання ніг лежачи",
                        nameEn: "Lying Leg Curl",
                        sets: 3, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "Повільна негативна фаза"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки стоячи",
                        nameEn: "Standing Calf Raise",
                        sets: 4, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Повна амплітуда"
                    )
                ]
            ),
            // День 3: Rest
            NippardDayTemplate(dayNumber: 3, workoutType: "Rest", exercises: []),
            // День 4: Push
            NippardDayTemplate(
                dayNumber: 4,
                workoutType: "Push",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим штанги над головою",
                        nameEn: "Overhead Press",
                        sets: 4, repsMin: 6, repsMax: 8, rir: 2,
                        restSeconds: 150, muscleGroup: "shoulders",
                        notes: "Головна вправа дня"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей на нахиленій лаві",
                        nameEn: "Incline DB Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Кут 30 градусів"
                    ),
                    NippardExerciseTemplate(
                        name: "Зведення рук у кросовері",
                        nameEn: "Cable Fly",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "chest",
                        notes: "Постійне напруження"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Легка вага, контроль"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання рук на блоці",
                        nameEn: "Tricep Pushdown",
                        sets: 3, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Лікті притиснуті"
                    ),
                    NippardExerciseTemplate(
                        name: "Французький жим лежачи",
                        nameEn: "Skull Crushers",
                        sets: 2, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Опускай до лоба"
                    )
                ]
            ),
            // День 5: Pull
            NippardDayTemplate(
                dayNumber: 5,
                workoutType: "Pull",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Станова тяга",
                        nameEn: "Deadlift",
                        sets: 3, repsMin: 5, repsMax: 8, rir: 2,
                        restSeconds: 180, muscleGroup: "back",
                        notes: "Один важкий підхід"
                    ),
                    NippardExerciseTemplate(
                        name: "Підтягування",
                        nameEn: "Pull-ups",
                        sets: 3, repsMin: 6, repsMax: 10, rir: 2,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Повна амплітуда"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга гантелі в нахилі",
                        nameEn: "Single Arm DB Row",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Повна ротація"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга на задні дельти",
                        nameEn: "Face Pull",
                        sets: 3, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Для здоров'я плечей"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання рук зі штангою",
                        nameEn: "Barbell Curl",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Без читінгу"
                    ),
                    NippardExerciseTemplate(
                        name: "Молотки",
                        nameEn: "Hammer Curl",
                        sets: 2, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Для брахіаліса"
                    )
                ]
            ),
            // День 6: Legs
            NippardDayTemplate(
                dayNumber: 6,
                workoutType: "Legs",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Гакк-присідання",
                        nameEn: "Hack Squat",
                        sets: 4, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 150, muscleGroup: "quads",
                        notes: "Вузька постановка ніг"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга з гантелями",
                        nameEn: "Dumbbell RDL",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "hamstrings",
                        notes: "Глибока розтяжка"
                    ),
                    NippardExerciseTemplate(
                        name: "Болгарські випади",
                        nameEn: "Bulgarian Split Squat",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "quads",
                        notes: "Контроль балансу"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання ніг сидячи",
                        nameEn: "Seated Leg Curl",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "Пік скорочення"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки сидячи",
                        nameEn: "Seated Calf Raise",
                        sets: 4, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Для камбаловидного"
                    )
                ]
            ),
            // День 7: Rest
            NippardDayTemplate(dayNumber: 7, workoutType: "Rest", exercises: [])
        ]
    )

    // MARK: - 5. Upper/Lower 6-Day Advanced

    static let upperLower6Day = NippardProgramTemplate(
        id: "upperlower-6day",
        name: "Upper/Lower 6-Day",
        nameUk: "Upper/Lower 6-денна",
        targetLevels: ["advanced"],
        frequencyDays: 6,
        maxSessionMinutes: 90,
        goal: "strength",
        description: "Максимальний об'єм та частота для досвідчених. Сила + гіпертрофія.",
        workoutDays: [
            NippardDayTemplate(
                dayNumber: 1,
                workoutType: "Lower #1",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Присідання зі штангою",
                        nameEn: "Barbell Back Squat",
                        sets: 5, repsMin: 5, repsMax: 6, rir: 2,
                        restSeconds: 180, muscleGroup: "quads",
                        notes: "Силовий фокус"
                    ),
                    NippardExerciseTemplate(
                        name: "Гакк-присідання",
                        nameEn: "Hack Squat",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Вузька постановка ніг"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга",
                        nameEn: "Romanian Deadlift",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "hamstrings",
                        notes: "Допоміжна вправа"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання ніг",
                        nameEn: "Leg Extension",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "quads",
                        notes: "Пік скорочення"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки стоячи",
                        nameEn: "Standing Calf Raise",
                        sets: 4, repsMin: 10, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Повна амплітуда"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 2,
                workoutType: "Upper #1",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим штанги лежачи",
                        nameEn: "Barbell Bench Press",
                        sets: 5, repsMin: 4, repsMax: 6, rir: 2,
                        restSeconds: 180, muscleGroup: "chest",
                        notes: "Силовий підхід"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга штанги в нахилі",
                        nameEn: "Barbell Row",
                        sets: 4, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 120, muscleGroup: "back",
                        notes: "Баланс push/pull"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей на нахиленій лаві",
                        nameEn: "Incline DB Press",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "chest",
                        notes: "Гіпертрофія"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга верхнього блоку",
                        nameEn: "Lat Pulldown",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Широкий хват"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 4, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Суперсет можливий"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання рук на блоці",
                        nameEn: "Tricep Pushdown",
                        sets: 3, repsMin: 10, repsMax: 15, rir: 2,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Фініш"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 3,
                workoutType: "Lower #2",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Станова тяга",
                        nameEn: "Conventional Deadlift",
                        sets: 4, repsMin: 4, repsMax: 6, rir: 2,
                        restSeconds: 180, muscleGroup: "back",
                        notes: "Силовий"
                    ),
                    NippardExerciseTemplate(
                        name: "Болгарські випади",
                        nameEn: "Bulgarian Split Squat",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Фокус на сідниці"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання ніг лежачи",
                        nameEn: "Lying Leg Curl",
                        sets: 4, repsMin: 10, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "Повільний темп"
                    ),
                    NippardExerciseTemplate(
                        name: "Гіперекстензія",
                        nameEn: "Back Extension",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 2,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "З вагою"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки сидячи",
                        nameEn: "Seated Calf Raise",
                        sets: 4, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Для камбаловидного"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 4,
                workoutType: "Upper #2",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Підтягування з вагою",
                        nameEn: "Weighted Pull-ups",
                        sets: 4, repsMin: 5, repsMax: 8, rir: 2,
                        restSeconds: 150, muscleGroup: "back",
                        notes: "Силовий"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим гантелей сидячи",
                        nameEn: "Seated DB Press",
                        sets: 4, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 120, muscleGroup: "shoulders",
                        notes: "Баланс push/pull"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга нижнього блоку",
                        nameEn: "Seated Cable Row",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "back",
                        notes: "Широкий хват"
                    ),
                    NippardExerciseTemplate(
                        name: "Зведення рук у кросовері",
                        nameEn: "Cable Fly",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 90, muscleGroup: "chest",
                        notes: "Ізоляція"
                    ),
                    NippardExerciseTemplate(
                        name: "Тяга на задні дельти",
                        nameEn: "Face Pull",
                        sets: 3, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "shoulders",
                        notes: "Здоров'я плечей"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання рук зі штангою",
                        nameEn: "Barbell Curl",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Строга техніка"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 5,
                workoutType: "Lower #3",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Фронтальні присідання",
                        nameEn: "Front Squat",
                        sets: 4, repsMin: 6, repsMax: 8, rir: 2,
                        restSeconds: 150, muscleGroup: "quads",
                        notes: "Вертикальний торс"
                    ),
                    NippardExerciseTemplate(
                        name: "Жим ногами",
                        nameEn: "Leg Press",
                        sets: 4, repsMin: 12, repsMax: 15, rir: 2,
                        restSeconds: 120, muscleGroup: "quads",
                        notes: "Об'ємна робота"
                    ),
                    NippardExerciseTemplate(
                        name: "Румунська тяга на одній нозі",
                        nameEn: "Single Leg RDL",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "hamstrings",
                        notes: "Баланс"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання ніг",
                        nameEn: "Leg Extension",
                        sets: 3, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 60, muscleGroup: "quads",
                        notes: "Пампінг"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом на носки в тренажері",
                        nameEn: "Calf Press",
                        sets: 4, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "calves",
                        notes: "Фініш"
                    )
                ]
            ),
            NippardDayTemplate(
                dayNumber: 6,
                workoutType: "Upper #3",
                exercises: [
                    NippardExerciseTemplate(
                        name: "Жим вузьким хватом",
                        nameEn: "Close Grip Bench",
                        sets: 4, repsMin: 8, repsMax: 10, rir: 2,
                        restSeconds: 120, muscleGroup: "triceps",
                        notes: "Компаунд для трицепсу"
                    ),
                    NippardExerciseTemplate(
                        name: "Підтягування вузьким хватом",
                        nameEn: "Close Grip Pull-ups",
                        sets: 3, repsMin: 8, repsMax: 12, rir: 2,
                        restSeconds: 120, muscleGroup: "biceps",
                        notes: "Компаунд для біцепсу"
                    ),
                    NippardExerciseTemplate(
                        name: "Французький жим",
                        nameEn: "Skull Crushers",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "triceps",
                        notes: "Ізоляція"
                    ),
                    NippardExerciseTemplate(
                        name: "Згинання рук на похилій лаві",
                        nameEn: "Incline DB Curl",
                        sets: 3, repsMin: 10, repsMax: 12, rir: 2,
                        restSeconds: 90, muscleGroup: "biceps",
                        notes: "Розтяжка"
                    ),
                    NippardExerciseTemplate(
                        name: "Розгинання рук над головою",
                        nameEn: "Overhead Extension",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "triceps",
                        notes: "Довга головка"
                    ),
                    NippardExerciseTemplate(
                        name: "Молотки на блоці",
                        nameEn: "Cable Hammer Curl",
                        sets: 3, repsMin: 12, repsMax: 15, rir: 1,
                        restSeconds: 60, muscleGroup: "biceps",
                        notes: "Брахіаліс"
                    ),
                    NippardExerciseTemplate(
                        name: "Підйом гантелей через сторони",
                        nameEn: "Lateral Raise",
                        sets: 4, repsMin: 15, repsMax: 20, rir: 1,
                        restSeconds: 45, muscleGroup: "shoulders",
                        notes: "Пампінг фініш"
                    )
                ]
            ),
            NippardDayTemplate(dayNumber: 7, workoutType: "Active Recovery", exercises: [])
        ]
    )
}
