import { Workout, Meal, WeightEntry, WorkoutProgram, ActiveWorkout, OmitId } from './types.js';
/**
 * Fetches workouts, meals, and weight entries from the server and populates the local 'db' object.
 * This should be called once when the app starts.
 */
export declare function initStorage(): Promise<void>;
export declare const getWorkouts: () => Workout[];
export declare const getWorkoutsByDate: (date: string) => Workout[];
export declare const getWorkoutById: (id: string) => Workout | undefined;
export declare function addWorkout(workoutData: OmitId<Workout>): Promise<void>;
export declare function updateWorkout(id: string, updates: Partial<Workout>): Promise<Workout | null>;
export declare function deleteWorkout(id: string): Promise<void>;
export declare const getMeals: () => Meal[];
export declare const getMealsByDate: (date: string) => Meal[];
export declare function addMeal(mealData: OmitId<Meal>): Promise<void>;
export declare function deleteMeal(id: string): Promise<void>;
export declare const getWeightEntries: () => WeightEntry[];
export declare const getWeightByDate: (date: string) => WeightEntry | undefined;
export declare function addWeightEntry(weightData: OmitId<WeightEntry>): Promise<void>;
export declare function deleteWeightEntry(id: string): Promise<void>;
export declare function getWorkoutPrograms(): WorkoutProgram[];
export declare function getWorkoutProgramById(id: string): WorkoutProgram | undefined;
export declare function addWorkoutProgram(programData: OmitId<WorkoutProgram>): Promise<void>;
export declare function getActiveWorkout(): ActiveWorkout | null;
export declare function saveActiveWorkout(workout: ActiveWorkout): void;
export declare function clearActiveWorkout(): void;
//# sourceMappingURL=storage.d.ts.map