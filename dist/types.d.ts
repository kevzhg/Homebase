export type OmitId<T> = Omit<T, 'id'>;
export type WorkoutType = 'strength' | 'cardio' | 'hiit' | 'yoga' | 'stretching' | 'sports' | 'other';
export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';
export type WeightUnit = 'lbs' | 'kg';
export declare const WORKOUT_TYPE_LABELS: Record<WorkoutType, string>;
export declare const MEAL_TYPE_LABELS: Record<MealType, string>;
export interface WorkoutSetEntry {
    setNumber: number;
    weight?: number;
    reps?: number | string;
    completed: boolean;
    completedAt?: string;
}
export interface WorkoutExerciseEntry {
    exerciseId: string;
    name: string;
    notes?: string;
    elapsedMs?: number;
    sets: WorkoutSetEntry[];
}
export interface Workout {
    id?: string;
    _id?: string;
    date: string;
    type: WorkoutType;
    durationMinutes: number;
    programName?: string;
    exercises: WorkoutExerciseEntry[];
    notes?: string;
    createdAt?: string;
    updatedAt?: string;
}
export interface Meal {
    id?: string;
    _id?: string;
    date: string;
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
    date: string;
    weight: number;
    unit: WeightUnit;
    notes?: string;
    createdAt?: string;
    updatedAt?: string;
}
export type ProgramType = 'push' | 'pull' | 'legs';
export interface Exercise {
    id: string;
    name: string;
    sets: number;
    reps: number | string;
    restTime: number;
    notes?: string;
}
export interface WorkoutProgram {
    id: string;
    name: ProgramType;
    displayName: string;
    exercises: Exercise[];
    createdAt: string;
}
export interface ExerciseSet {
    setNumber: number;
    completed: boolean;
    completedAt?: string;
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
    startTime: string;
    exercises: ActiveExercise[];
    currentExerciseIndex: number;
    isResting: boolean;
    restStartTime?: string;
    restDuration?: number;
    paused: boolean;
}
//# sourceMappingURL=types.d.ts.map