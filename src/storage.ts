import {
    Workout,
    Meal,
    WeightEntry,
    WorkoutProgram,
    ActiveWorkout,
    OmitId
} from './types.js';

const ACTIVE_WORKOUT_KEY = 'fitness-tracker-active-workout';
const API_BASE_URL = 'http://localhost:8000/api';

interface Database {
    workouts: Workout[];
    meals: Meal[];
    weight: WeightEntry[];
}

// This will hold all data fetched from the server
let db: Database = { workouts: [], meals: [], weight: [] };

/**
 * Fetches workouts, meals, and weight entries from the server and populates the local 'db' object.
 * This should be called once when the app starts.
 */
export async function initStorage(): Promise<void> {
    try {
        const [workouts, meals, weight] = await Promise.all([
            apiGet<Workout[]>('workouts'),
            apiGet<Meal[]>('meals'),
            apiGet<WeightEntry[]>('weight')
        ]);

        db.workouts = workouts.map(normalizeWorkout);
        db.meals = meals.map(normalizeMeal);
        db.weight = weight.map(normalizeWeight);
        console.log('Database initialized from server', db);
    } catch (error) {
        console.error("Error initializing storage:", error);
        // Initialize with empty structure if server fails
        db = { workouts: [], meals: [], weight: [] };
    }
}

// --- Generic API Functions ---

async function apiGet<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`);
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API GET to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
    return response.json();
}

async function apiPost<T>(endpoint: string, data: OmitId<T>): Promise<T> {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API POST to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
    return response.json();
}

async function apiPut<T>(endpoint: string, data: Partial<T>): Promise<T> {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API PUT to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
    return response.json();
}

async function apiDelete(endpoint: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`, { method: 'DELETE' });
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API DELETE to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
}

// Convert backend _id to id to keep frontend consistent
function normalizeWorkout(raw: Workout): Workout {
    const id = (raw as any).id ?? (raw as any)._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete (cleaned as any)._id;
    return cleaned;
}

function normalizeMeal(raw: Meal): Meal {
    const id = (raw as any).id ?? (raw as any)._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete (cleaned as any)._id;
    return cleaned;
}

function normalizeWeight(raw: WeightEntry): WeightEntry {
    const id = (raw as any).id ?? (raw as any)._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete (cleaned as any)._id;
    return cleaned;
}

// --- Workout Management ---

export const getWorkouts = (): Workout[] => db.workouts;
export const getWorkoutsByDate = (date: string): Workout[] => db.workouts.filter(w => w.date === date);
export const getWorkoutById = (id: string): Workout | undefined => db.workouts.find(w => w.id === id);

export async function addWorkout(workoutData: OmitId<Workout>): Promise<void> {
    try {
        const payload = { ...workoutData } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const newWorkout = normalizeWorkout(await apiPost<Workout>('workouts', payload as OmitId<Workout>));
        db.workouts.push(newWorkout);
        console.log('Workout saved successfully via API');
    } catch (error) {
        console.error('Error in addWorkout:', error);
        alert('Could not save workout. Please check the server connection and try again.');
        throw error; // Re-throw to stop calling function
    }
}

export async function updateWorkout(id: string, updates: Partial<Workout>): Promise<Workout | null> {
    try {
        const payload = { ...updates } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const updated = normalizeWorkout(await apiPut<Workout>(`workouts/${id}`, payload as Partial<Workout>));
        db.workouts = db.workouts.map(w => w.id === id ? updated : w);
        return updated;
    } catch (error) {
        console.error('Error in updateWorkout:', error);
        alert('Could not update workout. Please check the server connection and try again.');
        return null;
    }
}

export async function deleteWorkout(id: string): Promise<void> {
    try {
        await apiDelete(`workouts/${id}`);
        db.workouts = db.workouts.filter(w => w.id !== id);
    } catch (error) {
        console.error('Error in deleteWorkout:', error);
        alert('Could not delete workout. Please check the server connection and try again.');
        throw error;
    }
}

// --- Meal Management ---

export const getMeals = (): Meal[] => db.meals;
export const getMealsByDate = (date: string): Meal[] => db.meals.filter(m => m.date === date);

export async function addMeal(mealData: OmitId<Meal>): Promise<void> {
    try {
        const payload = { ...mealData } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const newMeal = normalizeMeal(await apiPost<Meal>('meals', payload as OmitId<Meal>));
        db.meals.push(newMeal);
    } catch (error) {
        console.error('Error in addMeal:', error);
        alert('Could not save meal. Please check the server connection and try again.');
        throw error;
    }
}

export async function deleteMeal(id: string): Promise<void> {
    try {
        await apiDelete(`meals/${id}`);
        db.meals = db.meals.filter(m => m.id !== id);
    } catch (error) {
        console.error('Error in deleteMeal:', error);
        alert('Could not delete meal. Please check the server connection and try again.');
        throw error;
    }
}

// --- Weight Management ---

export const getWeightEntries = (): WeightEntry[] => db.weight;
export const getWeightByDate = (date: string): WeightEntry | undefined => db.weight.find(w => w.date === date);

export async function addWeightEntry(weightData: OmitId<WeightEntry>): Promise<void> {
    try {
        const payload = { ...weightData } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const newWeight = normalizeWeight(await apiPost<WeightEntry>('weight', payload as OmitId<WeightEntry>));
        db.weight.push(newWeight);
    } catch (error) {
        console.error('Error in addWeightEntry:', error);
        alert('Could not save weight entry. Please check the server connection and try again.');
        throw error;
    }
}

export async function deleteWeightEntry(id:string): Promise<void> {
    try {
        await apiDelete(`weight/${id}`);
        db.weight = db.weight.filter(w => w.id !== id);
    } catch (error) {
        console.error('Error in deleteWeightEntry:', error);
        alert('Could not delete weight entry. Please check the server connection and try again.');
        throw error;
    }
}

// --- Workout Program Management (uses localStorage) ---
// These are fine to keep in localStorage as they are more like app configuration.

export function getWorkoutPrograms(): WorkoutProgram[] {
    const data = localStorage.getItem('fitness-tracker-programs');
    return data ? JSON.parse(data) : [];
}

export function getWorkoutProgramById(id: string): WorkoutProgram | undefined {
    return getWorkoutPrograms().find(p => p.id === id);
}

export async function addWorkoutProgram(programData: OmitId<WorkoutProgram>): Promise<void> {
    const programs = getWorkoutPrograms();
    const newProgram: WorkoutProgram = {
        ...programData,
        id: `program-${Date.now()}`,
        createdAt: new Date().toISOString()
    };
    programs.push(newProgram);
    localStorage.setItem('fitness-tracker-programs', JSON.stringify(programs));
}

// --- Active Workout Management (uses localStorage) ---
// This is session state, so localStorage is the perfect place for it.

export function getActiveWorkout(): ActiveWorkout | null {
    try {
        const data = localStorage.getItem(ACTIVE_WORKOUT_KEY);
        return data ? JSON.parse(data) : null;
    } catch (error) {
        console.error('Error getting active workout:', error);
        return null;
    }
}

export function saveActiveWorkout(workout: ActiveWorkout): void {
    localStorage.setItem(ACTIVE_WORKOUT_KEY, JSON.stringify(workout));
}

export function clearActiveWorkout(): void {
    localStorage.removeItem(ACTIVE_WORKOUT_KEY);
}
