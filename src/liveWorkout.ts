// Live Workout Module
// Handles active workout session, timers, and exercise tracking

import {
    WorkoutProgram,
    Exercise,
    ActiveWorkout,
    ActiveExercise,
    ExerciseSet,
    ProgramType
} from './types.js';

import {
    getActiveWorkout,
    saveActiveWorkout,
    clearActiveWorkout,
    getWorkoutPrograms,
    getWorkoutProgramById,
    addWorkout,
    addWorkoutProgram
} from './storage.js';

// Default workout programs (placeholder until user provides specifics)
const DEFAULT_PROGRAMS: Omit<WorkoutProgram, 'id'>[] = [
    {
        name: 'push',
        displayName: 'Push Day',
        exercises: [
            { id: 'push-1', name: 'Bench Press', sets: 4, reps: 8, restTime: 75, notes: 'Compound movement' },
            { id: 'push-2', name: 'Shoulder Press', sets: 4, reps: 10, restTime: 75 },
            { id: 'push-3', name: 'Incline Dumbbell Press', sets: 3, reps: 12, restTime: 75 },
            { id: 'push-4', name: 'Lateral Raises', sets: 3, reps: 15, restTime: 75 },
            { id: 'push-5', name: 'Tricep Dips', sets: 3, reps: 12, restTime: 75 },
            { id: 'push-6', name: 'Tricep Pushdowns', sets: 3, reps: 15, restTime: 75 }
        ],
        createdAt: new Date().toISOString()
    },
    {
        name: 'pull',
        displayName: 'Pull Day',
        exercises: [
            { id: 'pull-1', name: 'Deadlift', sets: 4, reps: 6, restTime: 75, notes: 'Heavy compound' },
            { id: 'pull-2', name: 'Pull-ups', sets: 4, reps: 10, restTime: 75 },
            { id: 'pull-3', name: 'Barbell Rows', sets: 4, reps: 10, restTime: 75 },
            { id: 'pull-4', name: 'Face Pulls', sets: 3, reps: 15, restTime: 75 },
            { id: 'pull-5', name: 'Barbell Curls', sets: 3, reps: 12, restTime: 75 },
            { id: 'pull-6', name: 'Hammer Curls', sets: 3, reps: 12, restTime: 75 }
        ],
        createdAt: new Date().toISOString()
    },
    {
        name: 'legs',
        displayName: 'Leg Day',
        exercises: [
            { id: 'legs-1', name: 'Squats', sets: 4, reps: 8, restTime: 75, notes: 'King of exercises' },
            { id: 'legs-2', name: 'Romanian Deadlifts', sets: 4, reps: 10, restTime: 75 },
            { id: 'legs-3', name: 'Leg Press', sets: 3, reps: 12, restTime: 75 },
            { id: 'legs-4', name: 'Leg Curls', sets: 3, reps: 12, restTime: 75 },
            { id: 'legs-5', name: 'Calf Raises', sets: 4, reps: 15, restTime: 75 },
            { id: 'legs-6', name: 'Lunges', sets: 3, reps: 12, restTime: 75 }
        ],
        createdAt: new Date().toISOString()
    }
];

// Timer state
let workoutTimer: number | null = null;
let restTimer: number | null = null;
let workoutStartTime: Date | null = null;
let restEndTime: number | null = null;

// Weight memory - stores last used weight per exercise
const EXERCISE_WEIGHTS_KEY = 'fitness-tracker-exercise-weights';

function getLastUsedWeight(exerciseId: string): number | undefined {
    try {
        const stored = localStorage.getItem(EXERCISE_WEIGHTS_KEY);
        if (stored) {
            const weights = JSON.parse(stored) as Record<string, number>;
            return weights[exerciseId];
        }
    } catch (error) {
        console.error('Error loading exercise weights:', error);
    }
    return undefined;
}

function saveLastUsedWeight(exerciseId: string, weight: number): void {
    try {
        const stored = localStorage.getItem(EXERCISE_WEIGHTS_KEY);
        const weights = stored ? JSON.parse(stored) : {};
        weights[exerciseId] = weight;
        localStorage.setItem(EXERCISE_WEIGHTS_KEY, JSON.stringify(weights));
    } catch (error) {
        console.error('Error saving exercise weight:', error);
    }
}


export async function initializeLiveWorkout(): Promise<void> {
    // Initialize programs if they don't exist
    const programs = getWorkoutPrograms();
    if (programs.length === 0) {
        console.log('Initializing default workout programs...');
        for (const program of DEFAULT_PROGRAMS) {
            await addWorkoutProgram(program);
        }
    }

    // Setup event listeners
    setupProgramSelection();
    setupWorkoutControls();

    // Check for active workout and resume if exists
    const activeWorkout = getActiveWorkout();
    if (activeWorkout) {
        resumeWorkout(activeWorkout);
    }
}

function setupProgramSelection(): void {
    const startButtons = document.querySelectorAll('.start-program-btn');
    startButtons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            const programName = (e.target as HTMLElement).getAttribute('data-program') as ProgramType;
            startWorkout(programName);
        });
    });
}

function setupWorkoutControls(): void {
    const resetBtn = document.getElementById('reset-workout-btn');
    const pauseBtn = document.getElementById('pause-workout-btn');
    const endBtn = document.getElementById('end-workout-btn');
    const skipRestBtn = document.getElementById('skip-rest-btn');
    const addRestBtn = document.getElementById('add-rest-time-btn');

    resetBtn?.addEventListener('click', resetWorkout);
    pauseBtn?.addEventListener('click', togglePauseWorkout);
    endBtn?.addEventListener('click', finishWorkout);
    skipRestBtn?.addEventListener('click', skipRest);
    addRestBtn?.addEventListener('click', () => addRestTime(30));
}

function startWorkout(programName: ProgramType): void {
    const programs = getWorkoutPrograms();
    const program = programs.find(p => p.name === programName);
    
    if (!program) {
        console.error('Program not found:', programName);
        return;
    }

    // Create active workout state
    const activeWorkout = createActiveWorkout(program);
    saveActiveWorkout(activeWorkout);
    workoutStartTime = new Date(activeWorkout.startTime);

    // Show active workout screen
    showActiveWorkoutScreen(program.displayName);
    renderExercises(program, activeWorkout);
    attachSetEventListeners();
    startWorkoutTimer();
}

function resumeWorkout(activeWorkout: ActiveWorkout): void {
    const program = getWorkoutProgramById(activeWorkout.programId);
    if (!program) return;

    workoutStartTime = new Date(activeWorkout.startTime);
    showActiveWorkoutScreen(activeWorkout.programName);
    renderExercises(program, activeWorkout);
    attachSetEventListeners();

    if (!activeWorkout.paused) {
        startWorkoutTimer();
        
        if (activeWorkout.isResting && activeWorkout.restStartTime && activeWorkout.restDuration) {
            const restStart = new Date(activeWorkout.restStartTime).getTime();
            const elapsed = Date.now() - restStart;
            const remaining = activeWorkout.restDuration - elapsed;
            
            if (remaining > 0) {
                startRestTimer(Math.floor(remaining / 1000));
            } else {
                stopResting();
            }
        }
    }
}

function showActiveWorkoutScreen(programName: string): void {
    const selection = document.getElementById('program-selection');
    const activeScreen = document.getElementById('active-workout-screen');
    const programNameEl = document.getElementById('active-program-name');

    if (selection) selection.style.display = 'none';
    if (activeScreen) activeScreen.style.display = 'block';
    if (programNameEl) programNameEl.textContent = programName;
}

function hideActiveWorkoutScreen(): void {
    const selection = document.getElementById('program-selection');
    const activeScreen = document.getElementById('active-workout-screen');

    if (selection) selection.style.display = 'block';
    if (activeScreen) activeScreen.style.display = 'none';
}

function renderExercises(program: WorkoutProgram, activeWorkout: ActiveWorkout): void {
    const container = document.getElementById('exercise-list');
    if (!container) return;

    container.innerHTML = program.exercises.map((exercise, index) => {
        const activeExercise = activeWorkout.exercises[index];
        const isActive = index === activeWorkout.currentExerciseIndex;
        const allCompleted = activeExercise.sets.every(s => s.completed);

        return `
            <div class="exercise-card ${isActive ? 'active' : ''} ${allCompleted ? 'completed' : ''}" data-exercise-index="${index}">
                <div class="exercise-card-header">
                    <div>
                        <div class="exercise-name">${exercise.name}</div>
                        <div class="exercise-info">${exercise.sets} sets × ${exercise.reps} reps • ${exercise.restTime}s rest</div>
                        ${exercise.notes ? `<div class="exercise-info"><em>${exercise.notes}</em></div>` : ''}
                    </div>
                    <span class="exercise-badge">${activeExercise.sets.filter(s => s.completed).length}/${exercise.sets}</span>
                </div>
                <div class="sets-grid">
                    ${activeExercise.sets.map((set, setIndex) => renderSet(exercise, set, setIndex, index, activeWorkout)).join('')}
                </div>
            </div>
        `;
    }).join('');
}

function renderSet(exercise: Exercise, set: ExerciseSet, setIndex: number, exerciseIndex: number, activeWorkout: ActiveWorkout): string {
    const isActive = exerciseIndex === activeWorkout.currentExerciseIndex && 
                     setIndex === activeWorkout.exercises[exerciseIndex].currentSet &&
                     !set.completed;
    
    // Get last used weight for this exercise
    const lastWeight = getLastUsedWeight(exercise.id);
    
    return `
        <div class="set-item ${set.completed ? 'completed' : ''} ${isActive ? 'active' : ''}" 
             data-exercise-index="${exerciseIndex}" 
             data-set-index="${setIndex}">
            <div class="set-number">Set ${set.setNumber}</div>
            <div class="set-reps">${exercise.reps} reps</div>
            ${!set.completed ? `
                <input type="number" 
                       class="set-weight-input" 
                       placeholder="Weight (lbs)" 
                       value="${lastWeight || ''}"
                       data-exercise-index="${exerciseIndex}" 
                       data-set-index="${setIndex}">
                <button class="btn btn-primary btn-small set-complete-btn" 
                        data-exercise-index="${exerciseIndex}" 
                        data-set-index="${setIndex}"
                        ${!isActive ? 'disabled' : ''}>
                    ${isActive ? 'Complete Set' : 'Locked'}
                </button>
            ` : `
                <div style="color: var(--success-color); margin-top: 0.5rem;">✓ Done</div>
                ${set.weight ? `<div style="font-size: 0.75rem; color: var(--text-secondary);">${set.weight} lbs</div>` : ''}
            `}
        </div>
    `;
}

export function refreshLiveWorkout(): void {
    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) {
        hideActiveWorkoutScreen();
        return;
    }

    const program = getWorkoutProgramById(activeWorkout.programId);
    if (program) {
        renderExercises(program, activeWorkout);
        
        // Re-attach event listeners
        attachSetEventListeners();
    }
}

function attachSetEventListeners(): void {
    const completeButtons = document.querySelectorAll('.set-complete-btn');
    completeButtons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            const exerciseIndex = parseInt((e.target as HTMLElement).getAttribute('data-exercise-index') || '0');
            const setIndex = parseInt((e.target as HTMLElement).getAttribute('data-set-index') || '0');
            completeSet(exerciseIndex, setIndex);
        });
    });
}

function completeSet(exerciseIndex: number, setIndex: number): void {
    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) return;

    const program = getWorkoutProgramById(activeWorkout.programId);
    if (!program) return;

    // Get weight input
    const weightInput = document.querySelector(
        `.set-weight-input[data-exercise-index="${exerciseIndex}"][data-set-index="${setIndex}"]`
    ) as HTMLInputElement;
    const weight = weightInput?.value ? parseFloat(weightInput.value) : undefined;

    // Mark set as completed
    activeWorkout.exercises[exerciseIndex].sets[setIndex].completed = true;
    activeWorkout.exercises[exerciseIndex].sets[setIndex].completedAt = new Date().toISOString();
    activeWorkout.exercises[exerciseIndex].sets[setIndex].weight = weight;

    // Save weight to memory for future use
    if (weight) {
        const exercise = program.exercises[exerciseIndex];
        saveLastUsedWeight(exercise.id, weight);
    }

    // Move to next set
    const exercise = activeWorkout.exercises[exerciseIndex];
    const nextSetIndex = exercise.sets.findIndex(s => !s.completed);
    
    if (nextSetIndex !== -1) {
        exercise.currentSet = nextSetIndex;
        
        // Start rest timer
        const restTime = program.exercises[exerciseIndex].restTime;
        startResting(restTime);
    } else {
        // All sets completed for this exercise, move to next exercise
        const nextExerciseIndex = activeWorkout.exercises.findIndex((ex, idx) => 
            idx > exerciseIndex && ex.sets.some(s => !s.completed)
        );
        
        if (nextExerciseIndex !== -1) {
            activeWorkout.currentExerciseIndex = nextExerciseIndex;
        }
    }

    saveActiveWorkout(activeWorkout);
    refreshLiveWorkout();
}

function startResting(seconds: number): void {
    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) return;

    activeWorkout.isResting = true;
    activeWorkout.restStartTime = new Date().toISOString();
    activeWorkout.restDuration = seconds * 1000;
    saveActiveWorkout(activeWorkout);

    startRestTimer(seconds);
}

function startRestTimer(seconds: number): void {
    const container = document.getElementById('rest-timer-container');
    const countdown = document.getElementById('rest-countdown');
    
    if (!container || !countdown) return;

    container.style.display = 'block';
    restEndTime = Date.now() + (seconds * 1000);

    // Clear existing timer
    if (restTimer) clearInterval(restTimer);

    // Update countdown display
    const updateRestDisplay = () => {
        if (!restEndTime) return;
        
        const remaining = Math.max(0, Math.floor((restEndTime - Date.now()) / 1000));
        const minutes = Math.floor(remaining / 60);
        const secs = remaining % 60;
        countdown.textContent = `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

        if (remaining === 0) {
            stopResting();
        }
    };

    updateRestDisplay();
    restTimer = window.setInterval(updateRestDisplay, 100);
}

function stopResting(): void {
    if (restTimer) {
        clearInterval(restTimer);
        restTimer = null;
    }

    const container = document.getElementById('rest-timer-container');
    if (container) container.style.display = 'none';

    const activeWorkout = getActiveWorkout();
    if (activeWorkout) {
        activeWorkout.isResting = false;
        activeWorkout.restStartTime = undefined;
        activeWorkout.restDuration = undefined;
        saveActiveWorkout(activeWorkout);
    }

    restEndTime = null;
}

function skipRest(): void {
    stopResting();
}

function addRestTime(seconds: number): void {
    if (restEndTime) {
        restEndTime += seconds * 1000;
        
        const activeWorkout = getActiveWorkout();
        if (activeWorkout && activeWorkout.restDuration) {
            activeWorkout.restDuration += seconds * 1000;
            saveActiveWorkout(activeWorkout);
        }
    }
}

function startWorkoutTimer(): void {
    const durationEl = document.getElementById('workout-duration');
    if (!durationEl || !workoutStartTime) return;

    // Clear existing timer
    if (workoutTimer) clearInterval(workoutTimer);

    const updateDuration = () => {
        if (!workoutStartTime) return;
        
        const elapsed = Date.now() - workoutStartTime.getTime();
        const minutes = Math.floor(elapsed / 60000);
        const seconds = Math.floor((elapsed % 60000) / 1000);
        durationEl.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    };

    updateDuration();
    workoutTimer = window.setInterval(updateDuration, 1000);
}

function stopWorkoutTimer(): void {
    if (workoutTimer) {
        clearInterval(workoutTimer);
        workoutTimer = null;
    }
}

function togglePauseWorkout(): void {
    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) return;

    const pauseBtn = document.getElementById('pause-workout-btn');
    if (!pauseBtn) return;

    activeWorkout.paused = !activeWorkout.paused;
    saveActiveWorkout(activeWorkout);

    if (activeWorkout.paused) {
        stopWorkoutTimer();
        if (activeWorkout.isResting) {
            stopResting();
        }
        pauseBtn.textContent = '▶️ Resume';
    } else {
        startWorkoutTimer();
        if (activeWorkout.isResting && activeWorkout.restStartTime && activeWorkout.restDuration) {
            const restStart = new Date(activeWorkout.restStartTime).getTime();
            const elapsed = Date.now() - restStart;
            const remaining = Math.max(0, activeWorkout.restDuration - elapsed);
            if (remaining > 0) {
                startRestTimer(Math.floor(remaining / 1000));
            }
        }
        pauseBtn.textContent = '⏸️ Pause';
    }
}

async function finishWorkout(): Promise<void> {
    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) return;

    const program = getWorkoutProgramById(activeWorkout.programId);
    if (!program) return;

    if (!confirm('Finish this workout?')) return;

    // Calculate total duration
    const endTime = new Date();
    const startTime = new Date(activeWorkout.startTime);
    const durationMinutes = Math.floor((endTime.getTime() - startTime.getTime()) / 60000);

    const completedSets = activeWorkout.exercises.flatMap(ex => ex.sets.filter(s => s.completed)).length;
    const totalSets = activeWorkout.exercises.flatMap(ex => ex.sets).length;

    // Format a simple summary for the notes
    const notesSummary = `Live workout - ${new Date(activeWorkout.startTime).toLocaleTimeString()} | ${activeWorkout.programName} | Duration: ${durationMinutes} min | Sets: ${completedSets}/${totalSets}`;

    // Build structured exercises with timing and set detail
    const structuredExercises = activeWorkout.exercises.map((ex, idx) => {
        const programExercise = program.exercises.find(e => e.id === ex.exerciseId);
        const elapsedMs = calculateExerciseElapsedMs(ex.sets);

        return {
            exerciseId: ex.exerciseId,
            name: programExercise?.name ?? `Exercise ${idx + 1}`,
            notes: programExercise?.notes,
            elapsedMs,
            sets: ex.sets.map(set => ({
                setNumber: set.setNumber,
                weight: set.weight,
                reps: programExercise?.reps,
                completed: set.completed,
                completedAt: set.completedAt
            }))
        };
    });

    // Save as regular workout with detailed data
    await addWorkout({
        date: activeWorkout.startTime.split('T')[0],
        type: 'strength',
        durationMinutes,
        programName: activeWorkout.programName,
        exercises: structuredExercises,
        notes: notesSummary
    });

    // Clean up
    stopWorkoutTimer();
    stopResting();
    clearActiveWorkout();
    workoutStartTime = null;

    // Show notification
    alert(`Workout saved! ${durationMinutes} min, ${completedSets}/${totalSets} sets`);
    
    // Reload page to refresh UI and show saved workout
    window.location.reload();
}

function resetWorkout(): void {
    if (!confirm('Reset this workout? All progress will be lost.')) return;

    const activeWorkout = getActiveWorkout();
    if (!activeWorkout) {
        console.warn('No active workout to reset.');
        return;
    }

    const program = getWorkoutProgramById(activeWorkout.programId);
    if (!program) {
        console.error('Program not found for reset:', activeWorkout.programId);
        return;
    }

    // Clean up timers and rest state
    stopWorkoutTimer();
    stopResting();
    restEndTime = null;

    // Build a fresh workout for the same program and persist it
    const freshWorkout = createActiveWorkout(program);
    saveActiveWorkout(freshWorkout);
    workoutStartTime = new Date(freshWorkout.startTime);

    // Ensure UI reflects reset state
    showActiveWorkoutScreen(program.displayName);
    renderExercises(program, freshWorkout);
    attachSetEventListeners();
    startWorkoutTimer();

    // Reset pause button label
    const pauseBtn = document.getElementById('pause-workout-btn');
    if (pauseBtn) pauseBtn.textContent = '⏸️ Pause';
}


// Cleanup timers on page unload
window.addEventListener('beforeunload', () => {
    if (workoutTimer) clearInterval(workoutTimer);
    if (restTimer) clearInterval(restTimer);
});

function calculateExerciseElapsedMs(sets: ExerciseSet[]): number | undefined {
    const completedTimestamps = sets
        .filter(s => s.completed && s.completedAt)
        .map(s => new Date(s.completedAt as string).getTime());

    if (completedTimestamps.length === 0) return undefined;

    const earliest = Math.min(...completedTimestamps);
    const latest = Math.max(...completedTimestamps);
    return Math.max(0, latest - earliest);
}

// Helper: create a fresh active workout state from a program
function createActiveWorkout(program: WorkoutProgram): ActiveWorkout {
    return {
        programId: program.id,
        programName: program.displayName,
        startTime: new Date().toISOString(),
        exercises: program.exercises.map(exercise => ({
            exerciseId: exercise.id,
            sets: Array.from({ length: exercise.sets }, (_, i) => ({
                setNumber: i + 1,
                completed: false
            })),
            currentSet: 0
        })),
        currentExerciseIndex: 0,
        isResting: false,
        paused: false
    };
}
