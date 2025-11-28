// Utility type to create a new type without the 'id' property
export type OmitId<T> = Omit<T, 'id'>;

// --- General Types ---

export type WorkoutType = 'strength' | 'cardio' | 'hiit' | 'yoga' | 'stretching' | 'sports' | 'other';
export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';
export type WeightUnit = 'lbs' | 'kg';

export const WORKOUT_TYPE_LABELS: Record<WorkoutType, string> = {
    strength: 'Strength',
    cardio: 'Cardio',
    hiit: 'HIIT',
    yoga: 'Yoga',
    stretching: 'Stretching',
    sports: 'Sports',
    other: 'Other'
};

export const MEAL_TYPE_LABELS: Record<MealType, string> = {
    breakfast: 'Breakfast',
    lunch: 'Lunch',
    dinner: 'Dinner',
    snack: 'Snack'
};

// --- Data Models (as stored in the database) ---

export interface WorkoutSetEntry {
    setNumber: number;
    weight?: number;
    reps?: number | string;
    completed: boolean;
    completedAt?: string; // ISO date string
}

export interface WorkoutExerciseEntry {
    exerciseId: string;
    name: string;
    notes?: string;
    elapsedMs?: number; // time spent on this exercise
    sets: WorkoutSetEntry[];
}

export interface Workout {
    id?: string; // convenience for frontend (maps from _id)
    _id?: string; // MongoDB ID as string
    date: string; // YYYY-MM-DD
    type: WorkoutType;
    durationMinutes: number; // total duration in minutes
    programName?: string;
    exercises: WorkoutExerciseEntry[];
    notes?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface Meal {
    id?: string;
    _id?: string;
    date: string; // YYYY-MM-DD
    type: MealType;
    name: string;
    calories?: number;
    protein?: number;
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface WeightEntry {
    id?: string;
    _id?: string;
    date: string; // YYYY-MM-DD
    weight: number;
    unit: WeightUnit;
    notes?: string;
    createdAt?: string;
    updatedAt?: string;
}

// --- Live Workout & Programs ---

export type ProgramType = 'push' | 'pull' | 'legs';

export interface Exercise {
    id: string;
    name: string;
    sets: number;
    reps: number | string; // e.g., 8 or "8-12"
    restTime: number; // in seconds
    notes?: string;
}

export interface WorkoutProgram {
    id: string;
    name: ProgramType;
    displayName: string;
    exercises: Exercise[];
    createdAt: string; // ISO date string
}

export interface ExerciseSet {
    setNumber: number;
    completed: boolean;
    completedAt?: string; // ISO date string
    weight?: number;
    actualReps?: number;
}

export interface ActiveExercise {
    exerciseId: string;
    sets: ExerciseSet[];
    currentSet: number;
    elapsedMs?: number;
}

export interface ActiveWorkout {
    programId: string;
    programName: string;
    startTime: string; // ISO date string
    exercises: ActiveExercise[];
    currentExerciseIndex: number;
    isResting: boolean;
    restStartTime?: string; // ISO date string
    restDuration?: number; // in milliseconds
    paused: boolean;
}
