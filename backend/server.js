require('dotenv').config();
const express = require('express');
const cors = require('cors');
const Anthropic = require('@anthropic-ai/sdk');

const app = express();
app.use(cors());
app.use(express.json());

const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Main analysis endpoint - generates health insights
app.post('/api/analyze', async (req, res) => {
    try {
        const { healthData } = req.body;

        if (!healthData) {
            return res.status(400).json({ error: 'healthData is required' });
        }

        const prompt = `Ти — AI-асистент здоров'я в додатку Fitify. Проаналізуй дані користувача та дай корисний інсайт.

ДАНІ ЗДОРОВ'Я:
- Пульс у спокої: ${healthData.restingHeartRate || 'невідомо'} уд/хв
- HRV: ${healthData.hrv || 'невідомо'} мс
- Сон: ${healthData.sleepHours || 'невідомо'} годин
- Глибокий сон: ${healthData.deepSleepMinutes || 'невідомо'} хв
- REM сон: ${healthData.remSleepMinutes || 'невідомо'} хв
- Кроки сьогодні: ${healthData.steps || 'невідомо'}
- Активні калорії: ${healthData.activeCalories || 'невідомо'} ккал
- Рівень стресу: ${healthData.stressLevel || 'невідомо'}%
- Recovery Score: ${healthData.recoveryScore || 'невідомо'}

ФОРМАТ ВІДПОВІДІ (JSON):
{
  "title": "Короткий заголовок інсайту (до 50 символів)",
  "content": "Детальний опис на 2-3 речення. Конкретні рекомендації.",
  "category": "recovery|sleep|activity|stress|illness|general",
  "priority": 1-3 (1=критично, 2=важливо, 3=інформативно)
}

ВАЖЛИВО:
- Пиши українською
- Будь конкретним і корисним
- Якщо бачиш проблеми — давай actionable поради
- Відповідай ТІЛЬКИ JSON, без markdown`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 500,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        // Parse JSON response
        let insight;
        try {
            insight = JSON.parse(responseText);
        } catch (parseError) {
            // If JSON parsing fails, create a structured response
            insight = {
                title: "Аналіз здоров'я",
                content: responseText,
                category: "general",
                priority: 3
            };
        }

        res.json({
            success: true,
            insight,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Analysis error:', error);
        res.status(500).json({
            error: 'Analysis failed',
            message: error.message
        });
    }
});

// Virus/illness risk check endpoint
app.post('/api/virus-check', async (req, res) => {
    try {
        const { healthData } = req.body;

        if (!healthData) {
            return res.status(400).json({ error: 'healthData is required' });
        }

        const prompt = `Ти — медичний AI-асистент. Оціни ризик хвороби на основі даних.

ДАНІ:
- Пульс у спокої: ${healthData.restingHeartRate || 'невідомо'} уд/хв (норма: 60-80)
- HRV: ${healthData.hrv || 'невідомо'} мс (вище = краще, норма: 40-100)
- Температура тіла: ${healthData.bodyTemperature || 'невідомо'}°C
- Якість сну: ${healthData.sleepQuality || 'невідомо'}%
- Кисень у крові: ${healthData.oxygenSaturation || 'невідомо'}%
- Респіраторна частота: ${healthData.respiratoryRate || 'невідомо'} вд/хв

ОЗНАКИ ХВОРОБИ:
- Підвищений пульс у спокої (+10-15 від норми)
- Знижений HRV (нижче 30)
- Температура > 37.2°C
- Погіршення якості сну
- SpO2 < 95%

ФОРМАТ ВІДПОВІДІ (JSON):
{
  "riskLevel": "low|medium|high",
  "confidence": 0.0-1.0,
  "recommendation": "Коротка рекомендація українською",
  "factors": ["фактор1", "фактор2"]
}

Відповідай ТІЛЬКИ JSON.`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 300,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let result;
        try {
            result = JSON.parse(responseText);
        } catch (parseError) {
            result = {
                riskLevel: "low",
                confidence: 0.5,
                recommendation: "Недостатньо даних для аналізу",
                factors: []
            };
        }

        res.json({
            success: true,
            ...result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Virus check error:', error);
        res.status(500).json({
            error: 'Virus check failed',
            message: error.message
        });
    }
});

// Generate workout program endpoint
app.post('/api/generate-program', async (req, res) => {
    try {
        const { userProfile } = req.body;

        if (!userProfile) {
            return res.status(400).json({ error: 'userProfile is required' });
        }

        // Extract all user profile data
        const {
            goal = 'buildMuscle',
            experience = 'beginner',
            gender = 'male',
            age = 25,
            weightKg = 70,
            trainingDaysPerWeek = 4,
            sessionDurationMinutes = 60,
            priorityMuscles = [],
            calculatedWeeklyVolume = 14,
            sleepHours = 'over7'
        } = userProfile;

        console.log('📥 User profile received:', userProfile);
        console.log('📅 Training days per week:', trainingDaysPerWeek);

        // Determine split based on days
        const splitType = trainingDaysPerWeek >= 5 ? 'PPL' :
                          trainingDaysPerWeek === 4 ? 'Upper-Lower' :
                          'Full Body';

        // Build PPL day names based on count
        let dayNamesHint = '';
        if (trainingDaysPerWeek === 5) {
            dayNamesHint = 'Дні: Push A, Pull A, Legs A, Push B, Pull B';
        } else if (trainingDaysPerWeek === 6) {
            dayNamesHint = 'Дні: Push A, Pull A, Legs A, Push B, Pull B, Legs B';
        } else if (trainingDaysPerWeek === 4) {
            dayNamesHint = 'Дні: Upper A, Lower A, Upper B, Lower B';
        } else if (trainingDaysPerWeek === 3) {
            dayNamesHint = 'Дні: Full Body A, Full Body B, Full Body C';
        }

        const prompt = `Ти тренер за методологією Джефа Ніпарда.
Відповідай ТІЛЬКИ валідним JSON, без markdown.

ПРОФІЛЬ КОРИСТУВАЧА:
- Ціль: ${goal}
- Досвід: ${experience}
- Стать: ${gender}, Вік: ${age}, Вага: ${weightKg}кг
- КІЛЬКІСТЬ ТРЕНУВАНЬ НА ТИЖДЕНЬ: ${trainingDaysPerWeek} (ОБОВ'ЯЗКОВО створи РІВНО ${trainingDaysPerWeek} днів!)
- Тривалість сесії: ${sessionDurationMinutes} хв
- Пріоритетні м'язи: ${priorityMuscles.length > 0 ? priorityMuscles.join(', ') : 'збалансовано'}
- Тижневий об'єм: ${calculatedWeeklyVolume} підходів/м'яз
- Сон: ${sleepHours}

ВИМОГИ:
1. Спліт: ${splitType}
2. РІВНО ${trainingDaysPerWeek} тренувальних днів у workoutDays
3. ${dayNamesHint}
4. 4-5 вправ на день
5. Короткі рядки (до 50 символів)

JSON схема:
{
  "programName": "string",
  "splitType": "${splitType}",
  "progressionStrategy": "string",
  "workoutDays": [${trainingDaysPerWeek} об'єктів з dayName, focus, exercises],
  "weeklySchedule": [${trainingDaysPerWeek} назв днів],
  "aiNotes": "string"
}

Кожна вправа: {name, sets, repsMin, repsMax, rir, restSeconds, muscleGroup}`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 8000,
            messages: [{ role: 'user', content: prompt }]
        });

        const rawText = message.content[0].text
            .replace(/```json\n?/g, '')
            .replace(/```\n?/g, '')
            .trim();

        console.log('Response length:', rawText.length);

        const program = JSON.parse(rawText);
        res.json({ success: true, program });

    } catch (error) {
        console.error('Generate program error:', error);
        res.status(500).json({
            error: 'Program generation failed',
            message: error.message
        });
    }
});

// Workout recommendation endpoint
app.post('/api/workout-recommendation', async (req, res) => {
    try {
        const { workoutLog, previousWorkout, userProfile } = req.body;

        if (!workoutLog) {
            return res.status(400).json({ error: 'workoutLog is required' });
        }

        const prompt = `Ти AI-тренер що використовує методологію Джефа Ніпарда.
Проаналізуй завершене тренування та дай рекомендації для наступного.

ЗАВЕРШЕНЕ ТРЕНУВАННЯ:
- Назва: ${workoutLog.workoutDayName}
- Тривалість: ${workoutLog.durationMinutes} хв
- Загальний об'єм: ${workoutLog.totalVolume} кг
- Виконані підходи:
${workoutLog.completedSets?.map(set =>
    `  • ${set.exerciseName}: ${set.weightKg}кг × ${set.reps} (RIR: ${set.rir})`
).join('\n') || 'Немає даних'}

${previousWorkout ? `ПОПЕРЕДНЄ ТРЕНУВАННЯ (для порівняння):
- Об'єм: ${previousWorkout.totalVolume} кг
- Підходи: ${previousWorkout.completedSets?.length || 0}` : ''}

ПРОФІЛЬ:
- Досвід: ${userProfile?.experience || 'intermediate'}
- Ціль: ${userProfile?.goal || 'buildMuscle'}

ФОРМАТ ВІДПОВІДІ (JSON):
{
  "readinessAssessment": "оцінка готовності до наступного тренування",
  "progressionAdvice": [
    {
      "exerciseName": "назва вправи",
      "currentWeight": поточна_вага,
      "recommendedWeight": рекомендована_вага,
      "reason": "причина рекомендації"
    }
  ],
  "overallAdvice": "загальна порада на основі аналізу",
  "motivationalNote": "мотивація в стилі Джефа Ніпарда (науково обґрунтована)"
}

Відповідай ТІЛЬКИ JSON українською.`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1000,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let recommendation;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            recommendation = JSON.parse(cleanJson);
        } catch (parseError) {
            recommendation = {
                readinessAssessment: "Аналіз недоступний",
                progressionAdvice: [],
                overallAdvice: responseText,
                motivationalNote: "Продовжуй тренуватись! Консистентність — ключ до успіху."
            };
        }

        res.json({
            success: true,
            ...recommendation,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Workout recommendation error:', error);
        res.status(500).json({
            error: 'Recommendation failed',
            message: error.message
        });
    }
});

// Weekly report endpoint - AI analysis of workout week
app.post('/api/weekly-report', async (req, res) => {
    try {
        const { workoutLogs, userProfile } = req.body;

        if (!workoutLogs || workoutLogs.length === 0) {
            return res.status(400).json({ error: 'workoutLogs is required' });
        }

        // Calculate weekly stats
        const totalWorkouts = workoutLogs.length;
        const totalVolume = workoutLogs.reduce((sum, log) => sum + (log.totalVolume || 0), 0);
        const totalDuration = workoutLogs.reduce((sum, log) => sum + (log.durationMinutes || 0), 0);
        const allSets = workoutLogs.flatMap(log => log.completedSets || []);
        const avgRIR = allSets.length > 0
            ? allSets.reduce((sum, set) => sum + (set.rir || 0), 0) / allSets.length
            : 2;

        // Group sets by exercise for progress analysis
        const exerciseStats = {};
        allSets.forEach(set => {
            if (!exerciseStats[set.exerciseName]) {
                exerciseStats[set.exerciseName] = { totalSets: 0, totalReps: 0, maxWeight: 0, rirs: [] };
            }
            exerciseStats[set.exerciseName].totalSets++;
            exerciseStats[set.exerciseName].totalReps += set.reps || 0;
            exerciseStats[set.exerciseName].maxWeight = Math.max(exerciseStats[set.exerciseName].maxWeight, set.weightKg || 0);
            exerciseStats[set.exerciseName].rirs.push(set.rir || 2);
        });

        const exerciseSummary = Object.entries(exerciseStats)
            .map(([name, stats]) => `${name}: ${stats.totalSets} підходів, макс ${stats.maxWeight}кг`)
            .join('\n');

        const prompt = `Ти AI-тренер що аналізує тижневий прогрес за методологією Джефа Ніпарда.

ТИЖНЕВІ ДАНІ:
- Тренувань за тиждень: ${totalWorkouts}
- Загальний об'єм: ${totalVolume.toFixed(0)} кг
- Загальний час: ${totalDuration} хв
- Середній RIR: ${avgRIR.toFixed(1)}
- Підходів виконано: ${allSets.length}

ПО ВПРАВАХ:
${exerciseSummary}

ПРОФІЛЬ:
- Досвід: ${userProfile?.experience || 'intermediate'}
- Ціль: ${userProfile?.goal || 'buildMuscle'}
- Тренувань заплановано: ${userProfile?.trainingDaysPerWeek || 4}/тиждень

ФОРМАТ ВІДПОВІДІ (JSON):
{
  "weekSummary": "Загальний підсумок тижня (1-2 речення)",
  "topProgress": [
    {"exercise": "назва", "insight": "що пішло добре"}
  ],
  "concerns": ["якщо є проблеми — список коротких пунктів"],
  "nextWeekFocus": "На що звернути увагу наступного тижня",
  "deloadNeeded": true/false,
  "motivationalNote": "Мотиваційна нотатка в стилі Ніпарда"
}

ПРАВИЛА:
- topProgress: 1-3 вправи з найкращим прогресом
- concerns: порожній масив якщо все добре
- deloadNeeded: true якщо avgRIR < 1.5 або 4+ тижні без розвантаження
- Пиши українською
- Відповідай ТІЛЬКИ JSON`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 800,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let report;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            report = JSON.parse(cleanJson);
        } catch (parseError) {
            report = {
                weekSummary: "Аналіз тижня недоступний",
                topProgress: [],
                concerns: [],
                nextWeekFocus: "Продовжуй тренуватись за планом",
                deloadNeeded: false,
                motivationalNote: "Консистентність — ключ до прогресу!"
            };
        }

        res.json({
            success: true,
            ...report,
            stats: {
                totalWorkouts,
                totalVolume: Math.round(totalVolume),
                totalDuration,
                avgRIR: parseFloat(avgRIR.toFixed(1)),
                totalSets: allSets.length
            },
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Weekly report error:', error);
        res.status(500).json({
            error: 'Weekly report failed',
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════════════════════
// DAILY READINESS - AI assessment of training readiness
// Uses Claude Haiku for fast, cheap responses
// ═══════════════════════════════════════════════════════════════════

const DAILY_READINESS_PROMPT = `Ти — персональний тренер і фахівець зі спортивної медицини.
Аналізуй дані здоров'я та дай КОНКРЕТНУ рекомендацію.
Відповідай ТІЛЬКИ JSON без markdown:
{
  "shouldTrain": boolean,
  "intensity": "heavy" | "moderate" | "light" | "rest",
  "headline": "одне речення — головна рекомендація",
  "reasoning": "2-3 речення — чому саме так",
  "keyMetric": "який показник вплинув найбільше",
  "warning": null або "попередження про здоров'я"
}`;

app.post('/api/daily-readiness', async (req, res) => {
    try {
        const { snapshot, plannedWorkout, recentWorkouts } = req.body;

        if (!snapshot) {
            return res.status(400).json({ error: 'snapshot is required' });
        }

        const recentWorkoutsText = recentWorkouts?.length > 0
            ? recentWorkouts.map(w => `- ${w.date || 'Дата'}: ${w.dayName || w.workoutDayName}, ${w.duration || w.durationMinutes} хв`).join('\n')
            : 'немає даних';

        const prompt = `Дані здоров'я (${new Date().toLocaleDateString('uk-UA')}):

ВІДНОВЛЕННЯ:
- Оцінка відновлення: ${snapshot.recoveryScore ?? 'н/д'}/100
- HRV сьогодні: ${snapshot.currentHRV ?? snapshot.heartRateVariability ?? 'н/д'} мс
- Тренд HRV (7 днів): ${snapshot.hrvTrend ?? 'н/д'}
- ЧСС у спокої: ${snapshot.restingHeartRate ?? 'н/д'} уд/хв
- Тренд ЧСС (14 днів): ${snapshot.restingHRTrend?.join(', ') ?? 'н/д'}

СОН (минула ніч):
- Тривалість: ${snapshot.sleepHours?.toFixed?.(1) ?? snapshot.sleepHours ?? 'н/д'} год
- Deep Sleep: ${snapshot.deepSleepMinutes ?? 'н/д'} хв
- REM Sleep: ${snapshot.remSleepMinutes ?? 'н/д'} хв

АКТИВНІСТЬ (сьогодні):
- Кроки: ${snapshot.stepCount?.toLocaleString?.() ?? snapshot.stepCount ?? 'н/д'}
- Активні калорії: ${snapshot.activeCalories ?? 'н/д'}

ЗАПЛАНОВАНЕ ТРЕНУВАННЯ: ${plannedWorkout || 'за програмою'}

ОСТАННІ 7 ДНІВ ТРЕНУВАНЬ:
${recentWorkoutsText}`;

        const message = await anthropic.messages.create({
            model: 'claude-haiku-4-5-20251001',
            max_tokens: 400,
            system: DAILY_READINESS_PROMPT,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let result;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            result = {
                shouldTrain: true,
                intensity: 'moderate',
                headline: 'Тренуйся за планом',
                reasoning: 'Недостатньо даних для детального аналізу.',
                keyMetric: 'recoveryScore',
                warning: null
            };
        }

        res.json({
            success: true,
            readiness: result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Daily readiness error:', error);
        res.status(500).json({
            error: 'Daily readiness failed',
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════════════════════
// POST-WORKOUT ANALYSIS - Deep analysis after workout completion
// Uses Claude Sonnet for detailed progression advice
// ═══════════════════════════════════════════════════════════════════

const POST_WORKOUT_PROMPT = `Ти — персональний тренер за методологією Джефа Ніпарда.
Аналізуй виконане тренування і давай КОНКРЕТНІ рекомендації.
Відповідай ТІЛЬКИ JSON:
{
  "overallRating": 1-10,
  "summary": "2 речення про тренування",
  "exerciseAdvice": [
    {
      "exerciseName": "...",
      "nextWeight": number,
      "nextWeightReason": "...",
      "volumeNote": "..."
    }
  ],
  "recoveryAdvice": "що робити наступні 24 год",
  "nextSessionTip": "фокус на наступному тренуванні",
  "motivationalNote": "..."
}`;

app.post('/api/post-workout-analysis', async (req, res) => {
    try {
        const { completedSets, exercises, duration, snapshot, previousLog } = req.body;

        if (!completedSets || !exercises) {
            return res.status(400).json({ error: 'completedSets and exercises are required' });
        }

        const exerciseSummary = exercises.map(ex => {
            const sets = completedSets.filter(s => s.exerciseId === ex.id || s.exerciseName === ex.name);
            const prevSets = previousLog?.completedSets?.filter(s => s.exerciseName === ex.name) ?? [];
            return `
${ex.name} (ціль: ${ex.sets}×${ex.repsMin}-${ex.repsMax}, RIR ${ex.rir}):
  Виконано: ${sets.map(s => `${s.weightKg}кг×${s.reps}повт RIR${s.rir}`).join(', ') || 'немає'}
  Попереднє: ${prevSets.length ? prevSets.map(s => `${s.weightKg}кг×${s.reps}повт`).join(', ') : 'перше тренування'}`;
        }).join('\n');

        const totalVolume = completedSets.reduce((acc, s) => acc + (s.weightKg || 0) * (s.reps || 0), 0);

        const prompt = `Тренування завершено:
- Тривалість: ${duration} хв
- Загальний об'єм: ${totalVolume.toFixed(0)} кг

${exerciseSummary}

СТАН ЗДОРОВ'Я ПІСЛЯ:
- ЧСС відновлення: ${snapshot?.heartRate ?? 'н/д'} уд/хв
- Загальний стан відновлення: ${snapshot?.recoveryScore ?? 'н/д'}/100`;

        const message = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1000,
            system: POST_WORKOUT_PROMPT,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let result;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            result = {
                overallRating: 7,
                summary: 'Тренування завершено.',
                exerciseAdvice: [],
                recoveryAdvice: 'Відпочинь і добре поїж.',
                nextSessionTip: 'Продовжуй за планом.',
                motivationalNote: 'Консистентність — ключ до успіху!'
            };
        }

        res.json({
            success: true,
            analysis: result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Post-workout analysis error:', error);
        res.status(500).json({
            error: 'Post-workout analysis failed',
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════════════════════
// MORNING BRIEFING - Personalized daily greeting with structured response
// Uses Claude Haiku for fast responses
// ═══════════════════════════════════════════════════════════════════

const MORNING_BRIEFING_PROMPT = `Ти — персональний AI тренер і тренер зі здоров'я.
Твоє ім'я — Віктор. Ти спілкуєшся тільки українською.
Тон: дружній, мотивуючий, конкретний. Без води.

Аналізуй дані і давай ОДИН конкретний вердикт на день.
Формат відповіді — ТІЛЬКИ JSON:
{
  "greeting": "коротке персональне привітання",
  "readinessScore": 0-100,
  "readinessEmoji": "🟢|🟡|🟠|🔴",
  "verdict": "одне речення — що робити сьогодні",
  "reasoning": [
    "факт 1 який вплинув на рішення",
    "факт 2",
    "факт 3 (опціонально)"
  ],
  "todayPlan": {
    "type": "heavy|moderate|light|rest|cardio",
    "suggestion": "конкретна пропозиція",
    "alternativeIfTired": "якщо юзер скаже що втомлений"
  },
  "healthNote": null або "важлива здоров'я нотатка"
}`;

app.post('/api/morning-briefing', async (req, res) => {
    try {
        const { snapshot, baseline, recentFeedback, plannedWorkout,
                subjectiveFeedback, workoutHistory } = req.body;

        if (!snapshot) {
            return res.status(400).json({ error: 'snapshot is required' });
        }

        // Calculate deviations from baseline
        const hrvDeviation = baseline?.medianHRV > 0
            ? ((snapshot.hrv - baseline.medianHRV) / baseline.medianHRV * 100).toFixed(1)
            : null;
        const hrDeviation = baseline?.medianRestingHR > 0
            ? ((snapshot.restingHR - baseline.medianRestingHR) / baseline.medianRestingHR * 100).toFixed(1)
            : null;

        const dateStr = new Date().toLocaleDateString('uk-UA', {
            weekday: 'long',
            day: 'numeric',
            month: 'long'
        });

        // Format subjective feedback
        const feedbackText = (subjectiveFeedback || recentFeedback)?.length > 0
            ? (subjectiveFeedback || recentFeedback).slice(-3).map(f =>
                `- "${f.text}" (${f.date || 'сьогодні'})`
              ).join('\n')
            : 'немає записів';

        // Format workout history
        const workoutHistoryText = workoutHistory?.length > 0
            ? workoutHistory.slice(-5).map(w =>
                `- ${w.date}: ${w.name}, ${w.duration}хв, об'єм ${w.volume}кг`
              ).join('\n')
            : 'немає даних';

        const prompt = `Дані на ${dateStr}:

ПОКАЗНИКИ СЬОГОДНІ VS ОСОБИСТА НОРМА:
- HRV: ${snapshot.hrv ?? snapshot.currentHRV ?? 'н/д'} мс (норма: ${baseline?.medianHRV?.toFixed?.(0) ?? 'н/д'} мс, відхилення: ${hrvDeviation ?? 'н/д'}%)
- ЧСС спокою: ${snapshot.restingHR ?? snapshot.restingHeartRate ?? 'н/д'} уд/хв (норма: ${baseline?.medianRestingHR?.toFixed?.(0) ?? 'н/д'}, відхилення: ${hrDeviation ?? 'н/д'}%)
- Температура зап'ястя: ${snapshot.wristTemp != null ? (snapshot.wristTemp > 0 ? '+' : '') + snapshot.wristTemp?.toFixed?.(2) + '°C від норми' : 'н/д'}

СОН:
- Тривалість: ${snapshot.sleepHours?.toFixed?.(1) ?? 'н/д'} год (норма: ${baseline?.medianSleepHours?.toFixed?.(1) ?? 'н/д'} год)
- Deep Sleep: ${snapshot.deepSleepMinutes ?? 'н/д'} хв
- REM: ${snapshot.remSleepMinutes ?? 'н/д'} хв

АКТИВНІСТЬ ВЧОРА:
- Кроки: ${snapshot.steps?.toLocaleString?.() ?? snapshot.steps ?? 'н/д'} (норма: ${baseline?.medianSteps?.toLocaleString?.() ?? baseline?.medianSteps ?? 'н/д'})
- Активні калорії: ${snapshot.activeCalories ?? 'н/д'} ккал

СУБ'ЄКТИВНІ ВІДЧУТТЯ (останні записи):
${feedbackText}

ОСТАННІ ТРЕНУВАННЯ:
${workoutHistoryText}

ЗАПЛАНОВАНЕ ТРЕНУВАННЯ: ${plannedWorkout?.dayName || plannedWorkout || 'за програмою'}`;

        const message = await anthropic.messages.create({
            model: 'claude-haiku-4-5-20251001',
            max_tokens: 600,
            system: MORNING_BRIEFING_PROMPT,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = message.content[0].text;

        let result;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            // Fallback if JSON parsing fails
            result = {
                greeting: "Привіт!",
                readinessScore: snapshot.recoveryScore || 70,
                readinessEmoji: "🟡",
                verdict: "Тренуйся за планом, прислухайся до тіла.",
                reasoning: ["Недостатньо даних для детального аналізу"],
                todayPlan: {
                    type: "moderate",
                    suggestion: "Тренування за програмою",
                    alternativeIfTired: "Легке кардіо або розтяжка"
                },
                healthNote: null
            };
        }

        res.json({
            success: true,
            briefing: result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Morning briefing error:', error);
        res.status(500).json({
            error: 'Morning briefing failed',
            message: error.message
        });
    }
});

// ═══════════════════════════════════════════════════════════════════
// COACH MESSAGE - Conversational AI coach with structured response
// Uses Claude Haiku for fast responses
// ═══════════════════════════════════════════════════════════════════

const COACH_CHAT_PROMPT = `Ти — персональний AI тренер Віктор. Спілкуєшся тільки українською.
Ти маєш доступ до даних здоров'я і тренувань юзера.
Тон: як досвідчений тренер-друг. Конкретний, мотивуючий.

ВАЖЛИВО:
- Якщо юзер скаржиться на болі/симптоми → обов'язково рекомендуй лікаря
- Якщо питає про харчування → давай загальні поради, не медичні
- Суб'єктивні відчуття записуй і враховуй в майбутніх рекомендаціях

Відповідай JSON:
{
  "message": "відповідь тренера",
  "action": null | "adjustWorkout" | "recordFeedback" | "suggestRest",
  "subjectiveTags": [] | ["втома", "біль", "мотивація"...],
  "sentiment": "positive|negative|neutral",
  "updatedPlan": null | { "type": "...", "reason": "..." }
}`;

app.post('/api/coach-message', async (req, res) => {
    try {
        const { userMessage, conversationHistory, snapshot,
                baseline, todayPlan, recentWorkouts } = req.body;

        if (!userMessage) {
            return res.status(400).json({ error: 'userMessage is required' });
        }

        const systemContext = `
Контекст юзера:
- Готовність сьогодні: ${snapshot?.recoveryScore ?? 'н/д'}/100
- HRV: ${snapshot?.hrv ?? snapshot?.currentHRV ?? 'н/д'} мс (норма: ${baseline?.medianHRV?.toFixed?.(0) ?? 'н/д'})
- Сон: ${snapshot?.sleepHours?.toFixed?.(1) ?? 'н/д'} год
- Заплановане тренування: ${todayPlan?.suggestion ?? 'не визначено'}`;

        // Build messages array with history
        const messages = [];

        if (conversationHistory?.length > 0) {
            // Add last 10 messages from history
            for (const msg of conversationHistory.slice(-10)) {
                messages.push({
                    role: msg.role,
                    content: msg.content
                });
            }
        }

        // Add current message with context
        messages.push({
            role: 'user',
            content: `${systemContext}\n\nПовідомлення: ${userMessage}`
        });

        const response = await anthropic.messages.create({
            model: 'claude-haiku-4-5-20251001',
            max_tokens: 500,
            system: COACH_CHAT_PROMPT,
            messages
        });

        const responseText = response.content[0].text;

        let result;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            // Fallback if JSON parsing fails
            result = {
                message: responseText,
                action: null,
                subjectiveTags: [],
                sentiment: "neutral",
                updatedPlan: null
            };
        }

        res.json({
            success: true,
            response: result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Coach message error:', error);
        res.status(500).json({
            error: 'Coach message failed',
            message: error.message
        });
    }
});

// Keep the old /api/coach-chat endpoint for backward compatibility
app.post('/api/coach-chat', async (req, res) => {
    try {
        const { message, conversationHistory, snapshot, baseline, plannedWorkout, recentFeedback } = req.body;

        if (!message) {
            return res.status(400).json({ error: 'message is required' });
        }

        // Forward to new endpoint format
        const newReq = {
            body: {
                userMessage: message,
                conversationHistory,
                snapshot,
                baseline,
                todayPlan: plannedWorkout ? { suggestion: plannedWorkout.dayName } : null,
                recentWorkouts: []
            }
        };

        // Inline handling for backward compatibility
        const systemContext = `
Контекст юзера:
- Готовність сьогодні: ${snapshot?.recoveryScore ?? 'н/д'}/100
- HRV: ${snapshot?.hrv ?? snapshot?.currentHRV ?? snapshot?.heartRateVariability ?? 'н/д'} мс
- Сон: ${snapshot?.sleepHours?.toFixed?.(1) ?? 'н/д'} год`;

        const messages = [];
        if (conversationHistory?.length > 0) {
            for (const msg of conversationHistory.slice(-10)) {
                messages.push({ role: msg.role, content: msg.content });
            }
        }
        messages.push({ role: 'user', content: `${systemContext}\n\nПовідомлення: ${message}` });

        const response = await anthropic.messages.create({
            model: 'claude-haiku-4-5-20251001',
            max_tokens: 500,
            system: COACH_CHAT_PROMPT,
            messages
        });

        const responseText = response.content[0].text;
        let result;
        try {
            result = JSON.parse(responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim());
        } catch {
            result = { message: responseText, action: null, subjectiveTags: [], sentiment: "neutral", updatedPlan: null };
        }

        res.json({
            success: true,
            response: result.message || responseText,
            structured: result,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Coach chat error:', error);
        res.status(500).json({ error: 'Coach chat failed', message: error.message });
    }
});

// ═══════════════════════════════════════════════════════════════════
// ANOMALY DETECTION - Weekly health trend analysis (run on Sundays)
// Uses Claude Sonnet for deep analysis
// ═══════════════════════════════════════════════════════════════════

const ANOMALY_PROMPT = `Ти — спортивний лікар і тренер. Аналізуй тренди здоров'я.
Шукай патерни які можуть свідчити про проблеми.
ТІЛЬКИ JSON відповідь:
{
  "anomalies": [
    {
      "type": "overtrained|illness|sleep_debt|cardiac|positive",
      "severity": "low|medium|high",
      "title": "назва аномалії",
      "description": "що саме помічено",
      "trend": "опис тренду",
      "recommendation": "конкретна порада",
      "shouldSeeDoctor": boolean,
      "doctorNote": null | "делікатне пояснення чому варто до лікаря"
    }
  ],
  "overallTrend": "improving|stable|declining",
  "weekScore": 1-10,
  "positiveNote": "щось хороше що помітив за тиждень"
}`;

// Helper functions for trend calculations
function calculateTrend(values) {
    const filtered = values.filter(v => v != null && !isNaN(v));
    if (filtered.length < 3) return 'недостатньо даних';
    const first = filtered.slice(0, Math.floor(filtered.length / 2));
    const last = filtered.slice(Math.floor(filtered.length / 2));
    const avgFirst = first.reduce((a, b) => a + b, 0) / first.length;
    const avgLast = last.reduce((a, b) => a + b, 0) / last.length;
    if (avgFirst === 0) return 'немає базових даних';
    const change = ((avgLast - avgFirst) / avgFirst * 100).toFixed(1);
    return `${change > 0 ? '+' : ''}${change}% за 14 днів`;
}

function countConsecutiveBelow(values, threshold) {
    let count = 0;
    for (let i = values.length - 1; i >= 0; i--) {
        if (values[i] != null && values[i] < threshold) count++;
        else break;
    }
    return count;
}

function countConsecutiveAbove(values, threshold) {
    let count = 0;
    for (let i = values.length - 1; i >= 0; i--) {
        if (values[i] != null && values[i] > threshold) count++;
        else break;
    }
    return count;
}

app.post('/api/anomaly-detection', async (req, res) => {
    try {
        const { history, baseline, recentWorkouts } = req.body;

        if (!history || !Array.isArray(history)) {
            return res.status(400).json({ error: 'history array is required' });
        }

        if (!baseline) {
            return res.status(400).json({ error: 'baseline is required' });
        }

        // Calculate trends from history
        const trends = {
            restingHRTrend: calculateTrend(history.map(d => d.restingHR)),
            hrvTrend: calculateTrend(history.map(d => d.hrv)),
            sleepTrend: calculateTrend(history.map(d => d.sleepHours)),

            // Count consecutive days below threshold
            consecutiveLowHRV: countConsecutiveBelow(
                history.map(d => d.hrv),
                (baseline.medianHRV || 50) * 0.9
            ),
            consecutiveHighHR: countConsecutiveAbove(
                history.map(d => d.restingHR),
                (baseline.medianRestingHR || 65) * 1.1
            ),
            consecutivePoorSleep: countConsecutiveBelow(
                history.map(d => d.sleepHours),
                6.5
            ),

            // Temperature anomalies (potential illness indicator)
            temperatureAnomalies: history.filter(d =>
                d.wristTemperature != null && Math.abs(d.wristTemperature) > 0.5
            ).length
        };

        // Format history data for prompt
        const historyText = history.slice(-14).map(d => {
            const date = new Date(d.date).toLocaleDateString('uk-UA', { day: 'numeric', month: 'short' });
            return `${date}: ЧСС=${d.restingHR ?? 'н/д'}, HRV=${d.hrv ?? 'н/д'}, ` +
                   `сон=${d.sleepHours?.toFixed?.(1) ?? d.sleepHours ?? 'н/д'}год` +
                   (d.wristTemperature != null ? `, темп=${d.wristTemperature > 0 ? '+' : ''}${d.wristTemperature.toFixed(2)}°C` : '');
        }).join('\n');

        const prompt = `
АНАЛІЗ 14-ДЕННОГО ТРЕНДУ:

БАЗЛАЙН (особиста норма юзера):
- HRV норма: ${baseline.medianHRV?.toFixed?.(0) ?? baseline.medianHRV ?? 'н/д'} мс (±${baseline.stdevHRV?.toFixed?.(0) ?? baseline.stdevHRV ?? 'н/д'})
- ЧСС норма: ${baseline.medianRestingHR?.toFixed?.(0) ?? baseline.medianRestingHR ?? 'н/д'} уд/хв (±${baseline.stdevRestingHR?.toFixed?.(0) ?? baseline.stdevRestingHR ?? 'н/д'})
- Сон норма: ${baseline.medianSleepHours?.toFixed?.(1) ?? baseline.medianSleepHours ?? 'н/д'} год

ТРЕНДИ:
- ЧСС спокою: ${trends.restingHRTrend} (підвищений ${trends.consecutiveHighHR} днів підряд)
- HRV: ${trends.hrvTrend} (низький ${trends.consecutiveLowHRV} днів підряд)
- Сон: ${trends.sleepTrend} (поганий сон ${trends.consecutivePoorSleep} ночей)
- Температурні аномалії: ${trends.temperatureAnomalies} з 14 днів

ТИЖНЕВІ ДАНІ (останні 14 днів):
${historyText}

ТРЕНУВАННЯ ЗА ТИЖДЕНЬ: ${recentWorkouts?.length ?? 0} тренувань`;

        const response = await anthropic.messages.create({
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1000,
            system: ANOMALY_PROMPT,
            messages: [{ role: 'user', content: prompt }]
        });

        const responseText = response.content[0].text;

        let result;
        try {
            const cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            result = {
                anomalies: [],
                overallTrend: 'stable',
                weekScore: 7,
                positiveNote: 'Аналіз недоступний через помилку парсингу.'
            };
        }

        res.json({
            success: true,
            analysis: result,
            trends,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Anomaly detection error:', error);
        res.status(500).json({
            error: 'Anomaly detection failed',
            message: error.message
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Fitify Backend running on http://localhost:${PORT}`);
    console.log('Endpoints:');
    console.log('  GET  /health                    - Health check');
    console.log('  POST /api/analyze               - Generate health insight');
    console.log('  POST /api/virus-check           - Check illness risk');
    console.log('  POST /api/generate-program      - Generate workout program');
    console.log('  POST /api/workout-recommendation - Get workout advice');
    console.log('  POST /api/weekly-report         - Get weekly training report');
    console.log('  POST /api/daily-readiness       - Get daily training readiness');
    console.log('  POST /api/post-workout-analysis - Get post-workout analysis');
    console.log('  POST /api/morning-briefing      - Get morning briefing');
    console.log('  POST /api/coach-message         - Send message to AI coach');
    console.log('  POST /api/coach-chat            - Chat with AI coach (legacy)');
    console.log('  POST /api/anomaly-detection     - Weekly health anomaly detection');
});
