import {
    Training,
    Meal,
    WeightEntry,
    WorkoutProgram,
    WorkoutProgramDocument,
    WorkoutProgramInput,
    Exercise,
    ExerciseType,
    ActiveWorkout,
    OmitId,
    OnigiriPlanner,
    ExerciseLibraryItem
} from './types.js';

const ACTIVE_WORKOUT_KEY = 'fitness-tracker-active-workout';
const WORKOUT_PROGRAMS_KEY = 'fitness-tracker-programs';
const EXERCISES_KEY = 'fitness-tracker-exercises';
const ONIGIRI_PLANNER_KEY = 'onigiri-planner';
// Allow overriding the API base URL via a global for prod (GitHub Pages) while keeping localhost as the dev default.
const API_BASE_URL = (typeof window !== 'undefined' && (window as any).API_BASE_URL) || 'http://localhost:8000/api';

function generateProgramId(existingIds?: Set<string>): string {
    const used = existingIds ?? new Set<string>();
    let id = '';
    do {
        id = `program-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
    } while (used.has(id));
    return id;
}

function generatePlannerId(): string {
    return `onigiri-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
}

interface Database {
    trainings: Training[];
    meals: Meal[];
    weight: WeightEntry[];
    onigiriPlanner?: OnigiriPlanner;
}

// This will hold all data fetched from the server
let db: Database = { trainings: [], meals: [], weight: [] };
let programCache: WorkoutProgram[] = [];
let exerciseCache: ExerciseLibraryItem[] = [];

/**
 * Fetches trainings, meals, and weight entries from the server and populates the local 'db' object.
 * This should be called once when the app starts.
 */
export async function initStorage(): Promise<void> {
    try {
        const [trainings, meals, weight, programs, exercises] = await Promise.all([
            apiGet<Training[]>('trainings'),
            apiGet<Meal[]>('meals'),
            apiGet<WeightEntry[]>('weight'),
            apiGet<WorkoutProgramDocument[]>('programs'),
            apiGet<ExerciseLibraryItem[]>('exercises')
        ]);

        db.trainings = trainings.map(normalizeTraining);
        db.meals = meals.map(normalizeMeal);
        db.weight = weight.map(normalizeWeight);
        hydrateProgramCache(programs);
        hydrateExerciseCache(exercises);
        console.log('Database initialized from server', db);
    } catch (error) {
        console.error("Error initializing storage:", error);
        // Initialize with empty structure if server fails
        db = { trainings: [], meals: [], weight: [] };
        // Fallback to local programs if API unavailable
        programCache = loadProgramsFromLocal();
        exerciseCache = loadExercisesFromLocal();
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
function normalizeTraining(raw: Training): Training {
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

function normalizeOnigiriPlanner(raw: OnigiriPlanner): OnigiriPlanner {
    const plannerId = (raw as any).id ?? (raw as any)._id ?? generatePlannerId();
    const sections = Array.isArray(raw.sections) ? raw.sections : [];
    const normalizedSections = sections.map(section => {
        const sectionId = (section as any).id ?? generatePlannerId();
        const items = Array.isArray(section.items) ? section.items : [];
        const normalizedItems = items.map(item => ({
            id: (item as any).id ?? generatePlannerId(),
            title: item.title ?? 'New Item',
            notes: item.notes ?? '',
            weight: typeof item.weight === 'number' && Number.isFinite(item.weight) && item.weight > 0 ? item.weight : 1,
            done: Boolean(item.done),
            completion: item.completion,
            updatedAt: item.updatedAt
        }));

        return {
            id: sectionId,
            name: section.name ?? 'Untitled Section',
            weight: typeof section.weight === 'number' && Number.isFinite(section.weight) && section.weight > 0 ? section.weight : 1,
            items: normalizedItems,
            completion: section.completion,
            updatedAt: section.updatedAt
        };
    });

    return {
        id: String(plannerId),
        sections: normalizedSections,
        completion: raw.completion,
        updatedAt: raw.updatedAt
    };
}

function normalizeWorkoutProgram(raw: WorkoutProgramDocument): WorkoutProgram {
    const id = (raw as any).id ?? (raw as any)._id ?? `program-${Date.now()}`;
    const cleaned: WorkoutProgram = ensureExerciseTypes({
        ...raw,
        id: String(id),
        createdAt: raw.createdAt ?? new Date().toISOString(),
        updatedAt: raw.updatedAt,
        source: raw.source ?? 'api'
    });
    delete (cleaned as any)._id;
    return cleaned;
}

function normalizeAndDedupePrograms(rawPrograms: WorkoutProgramDocument[]): { programs: WorkoutProgram[]; updated: boolean } {
    const seen = new Set<string>();
    const programs: WorkoutProgram[] = [];
    let updated = false;

    for (const raw of rawPrograms) {
        const normalized = normalizeWorkoutProgram(raw);
        let programId = normalized.id;
        if (!programId || seen.has(programId)) {
            programId = generateProgramId(seen);
            normalized.id = programId;
            updated = true;
        }
        seen.add(programId);
        programs.push(normalized);
    }

    return { programs, updated };
}

function ensureExerciseTypes<T extends { exercises: Exercise[] }>(program: T): T {
    const withTypes = {
        ...program,
        exercises: program.exercises.map(ex => ({
            ...ex,
            exerciseType: ex.exerciseType ?? ('compound' as ExerciseType)
        }))
    };
    return withTypes;
}

function normalizeExerciseItem(raw: ExerciseLibraryItem): ExerciseLibraryItem {
    const id = (raw as any).id ?? (raw as any)._id ?? `exercise-${Date.now()}`;
    const sets = typeof raw.sets === 'number' && Number.isFinite(raw.sets) && raw.sets > 0 ? raw.sets : 3;
    const restTime = typeof raw.restTime === 'number' && Number.isFinite(raw.restTime) && raw.restTime >= 0 ? raw.restTime : 60;
    const reps = raw.reps ?? '10';
    const cleaned: ExerciseLibraryItem = {
        ...raw,
        id: String(id),
        category: (raw as any).category ?? 'push',
        exerciseType: (raw as any).exerciseType ?? raw.exerciseType ?? 'compound',
        sets,
        reps,
        restTime
    };
    delete (cleaned as any)._id;
    return cleaned;
}

function loadProgramsFromLocal(): WorkoutProgram[] {
    try {
        const data = localStorage.getItem(WORKOUT_PROGRAMS_KEY);
        if (!data) return [];
        const rawPrograms = JSON.parse(data) as WorkoutProgramDocument[];
        const { programs } = normalizeAndDedupePrograms(rawPrograms);
        return programs.map(p => ensureExerciseTypes(p));
    } catch (error) {
        console.error('Error loading workout programs:', error);
        return [];
    }
}

function loadExercisesFromLocal(): ExerciseLibraryItem[] {
    try {
        const data = localStorage.getItem(EXERCISES_KEY);
        if (!data) return [];
        const raw = JSON.parse(data) as ExerciseLibraryItem[];
        return raw.map(normalizeExerciseItem);
    } catch (error) {
        console.error('Error loading exercises:', error);
        return [];
    }
}

function hydrateProgramCache(rawPrograms: WorkoutProgramDocument[]): void {
    const { programs } = normalizeAndDedupePrograms(rawPrograms);
    programCache = programs.map(p => ensureExerciseTypes(p));
    localStorage.setItem(WORKOUT_PROGRAMS_KEY, JSON.stringify(programCache));
}

function hydrateExerciseCache(rawExercises: ExerciseLibraryItem[]): void {
    exerciseCache = rawExercises.map(normalizeExerciseItem);
    localStorage.setItem(EXERCISES_KEY, JSON.stringify(exerciseCache));
}

// --- Training Management ---

export const getTrainings = (): Training[] => db.trainings;
export const getTrainingsByDate = (date: string): Training[] => db.trainings.filter(w => w.date === date);
export const getTrainingById = (id: string): Training | undefined => db.trainings.find(w => w.id === id);

export async function addTraining(trainingData: OmitId<Training>): Promise<void> {
    try {
        const payload = { ...trainingData } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const newTraining = normalizeTraining(await apiPost<Training>('trainings', payload as OmitId<Training>));
        db.trainings.push(newTraining);
        console.log('Training saved successfully via API');
    } catch (error) {
        console.error('Error in addTraining:', error);
        alert('Could not save training. Please check the server connection and try again.');
        throw error; // Re-throw to stop calling function
    }
}

export async function updateTraining(id: string, updates: Partial<Training>): Promise<Training | null> {
    try {
        const payload = { ...updates } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;

        const updated = normalizeTraining(await apiPut<Training>(`trainings/${id}`, payload as Partial<Training>));
        db.trainings = db.trainings.map(w => w.id === id ? updated : w);
        return updated;
    } catch (error) {
        console.error('Error in updateTraining:', error);
        alert('Could not update training. Please check the server connection and try again.');
        return null;
    }
}

export async function deleteTraining(id: string): Promise<void> {
    try {
        await apiDelete(`trainings/${id}`);
        db.trainings = db.trainings.filter(w => w.id !== id);
    } catch (error) {
        console.error('Error in deleteTraining:', error);
        alert('Could not delete training. Please check the server connection and try again.');
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
// These are fine to keep in localStorage as they are more like app configuration,
// but persistence hooks are ready for a future Mongo-backed collection.

export function getWorkoutPrograms(): WorkoutProgram[] {
    if (programCache.length) return programCache;
    programCache = loadProgramsFromLocal();
    return programCache;
}

export function getWorkoutProgramById(id: string): WorkoutProgram | undefined {
    return getWorkoutPrograms().find(p => p.id === id);
}

export async function addWorkoutProgram(programData: WorkoutProgramInput): Promise<WorkoutProgram> {
    const programs = getWorkoutPrograms();
    const existingIds = new Set(programs.map(p => p.id).filter(Boolean) as string[]);
    const now = new Date().toISOString();
    const newProgram: WorkoutProgram = ensureExerciseTypes({
        ...programData,
        id: programData.id ?? generateProgramId(existingIds),
        createdAt: programData.createdAt ?? now,
        updatedAt: now,
        source: programData.source ?? 'api'
    });
    try {
        const saved = normalizeWorkoutProgram(
            await apiPost<WorkoutProgramDocument>('programs', newProgram as WorkoutProgramDocument)
        );
        const next = [...programs.filter(p => p.id !== saved.id), saved];
        persistWorkoutPrograms(next);
        return saved;
    } catch (error) {
        console.error('Error saving workout program:', error);
        alert('Could not save workout program. Please check the server connection and try again.');
        throw error;
    }
}

export async function updateWorkoutProgram(id: string, updates: Partial<WorkoutProgram>): Promise<WorkoutProgram | null> {
    const programs = getWorkoutPrograms();
    const idx = programs.findIndex(p => p.id === id);
    if (idx === -1) return null;

    const updated: WorkoutProgram = ensureExerciseTypes({
        ...programs[idx],
        ...updates,
        updatedAt: new Date().toISOString()
    });

    try {
        const saved = normalizeWorkoutProgram(
            await apiPut<WorkoutProgramDocument>(`programs/${id}`, updated as Partial<WorkoutProgramDocument>)
        );
        programs[idx] = saved;
        persistWorkoutPrograms(programs);
        return saved;
    } catch (error) {
        console.error('Error updating workout program:', error);
        alert('Could not update workout program. Please check the server connection and try again.');
        return null;
    }
}

export async function deleteWorkoutProgram(id: string): Promise<void> {
    try {
        await apiDelete(`programs/${id}`);
        const programs = getWorkoutPrograms().filter(p => p.id !== id);
        persistWorkoutPrograms(programs);
    } catch (error) {
        console.error('Error deleting workout program:', error);
        alert('Could not delete workout program. Please check the server connection and try again.');
        throw error;
    }
}

export async function cloneWorkoutProgram(id: string): Promise<WorkoutProgram | null> {
    const programs = getWorkoutPrograms();
    const program = programs.find(p => p.id === id);
    if (!program) return null;

    const now = new Date().toISOString();
    const clonedExercises: Exercise[] = program.exercises.map(ex => ({ ...ex, exerciseType: ex.exerciseType ?? 'compound' }));
    const existingIds = new Set(programs.map(p => p.id).filter(Boolean) as string[]);
    const clone: WorkoutProgram = {
        ...program,
        id: generateProgramId(existingIds),
        displayName: `${program.displayName} (Copy)`,
        createdAt: now,
        updatedAt: now,
        exercises: clonedExercises,
        source: 'api'
    };

    return addWorkoutProgram(clone);
}

function persistWorkoutPrograms(programs: WorkoutProgram[]): void {
    programCache = programs;
    localStorage.setItem(WORKOUT_PROGRAMS_KEY, JSON.stringify(programs));
}

// --- Exercise Library Management ---

export function getExerciseLibraryItems(): ExerciseLibraryItem[] {
    if (exerciseCache.length) return exerciseCache;
    exerciseCache = loadExercisesFromLocal();
    return exerciseCache;
}

export async function addExerciseDefinition(exercise: OmitId<ExerciseLibraryItem>): Promise<ExerciseLibraryItem> {
    try {
        const payload = {
            ...exercise,
            sets: exercise.sets && exercise.sets > 0 ? exercise.sets : 3,
            reps: exercise.reps ?? '10',
            restTime: typeof exercise.restTime === 'number' && exercise.restTime >= 0 ? exercise.restTime : 60
        } as Record<string, unknown>;
        delete payload.id;
        delete payload._id;
        const saved = normalizeExerciseItem(await apiPost<ExerciseLibraryItem>('exercises', payload as OmitId<ExerciseLibraryItem>));
        exerciseCache = [...exerciseCache.filter(ex => ex.id !== saved.id), saved];
        localStorage.setItem(EXERCISES_KEY, JSON.stringify(exerciseCache));
        return saved;
    } catch (error) {
        console.error('Error saving exercise:', error);
        alert('Could not save exercise. Please check the server connection and try again.');
        throw error;
    }
}

export async function updateExerciseDefinition(id: string, updates: Partial<ExerciseLibraryItem>): Promise<ExerciseLibraryItem | null> {
    const existing = exerciseCache.find(ex => ex.id === id);
    if (!existing) return null;
    try {
        const merged = {
            ...existing,
            ...updates,
            sets: typeof updates.sets === 'number' && updates.sets > 0 ? updates.sets : existing.sets ?? 3,
            reps: updates.reps ?? existing.reps ?? '10',
            restTime: typeof updates.restTime === 'number' && updates.restTime >= 0 ? updates.restTime : existing.restTime ?? 60
        } as ExerciseLibraryItem;

        const payload = { ...merged } as Record<string, unknown>;
        delete payload._id;

        const saved = normalizeExerciseItem(
            await apiPut<ExerciseLibraryItem>(`exercises/${id}`, payload as Partial<ExerciseLibraryItem>)
        );

        exerciseCache = exerciseCache.map(ex => (ex.id === id ? saved : ex));
        localStorage.setItem(EXERCISES_KEY, JSON.stringify(exerciseCache));
        return saved;
    } catch (error) {
        console.error('Error updating exercise:', error);
        alert('Could not update exercise. Please check the server connection and try again.');
        return null;
    }
}

// --- Onigiri Planner (API-first with local fallback) ---

function getLocalOnigiriPlanner(): OnigiriPlanner | null {
    try {
        const data = localStorage.getItem(ONIGIRI_PLANNER_KEY);
        return data ? normalizeOnigiriPlanner(JSON.parse(data)) : null;
    } catch (error) {
        console.error('Error loading local Onigiri planner:', error);
        return null;
    }
}

function saveLocalOnigiriPlanner(planner: OnigiriPlanner): void {
    try {
        localStorage.setItem(ONIGIRI_PLANNER_KEY, JSON.stringify(planner));
    } catch (error) {
        console.error('Error saving local Onigiri planner:', error);
    }
}

export async function getOnigiriPlanner(): Promise<OnigiriPlanner> {
    try {
        const remote = await apiGet<OnigiriPlanner>('onigiri');
        const normalized = normalizeOnigiriPlanner(remote);
        db.onigiriPlanner = normalized;
        saveLocalOnigiriPlanner(normalized);
        return normalized;
    } catch (error) {
        console.error('Error fetching Onigiri planner from API:', error);
        const local = getLocalOnigiriPlanner();
        if (local) {
            db.onigiriPlanner = local;
            return local;
        }
        throw error;
    }
}

export async function saveOnigiriPlanner(planner: OnigiriPlanner): Promise<OnigiriPlanner> {
    try {
        const payload = { ...planner } as Record<string, unknown>;
        delete payload._id;
        const saved = normalizeOnigiriPlanner(await apiPut<OnigiriPlanner>('onigiri', payload as Partial<OnigiriPlanner>));
        db.onigiriPlanner = saved;
        saveLocalOnigiriPlanner(saved);
        return saved;
    } catch (error) {
        console.error('Error saving Onigiri planner:', error);
        saveLocalOnigiriPlanner(planner);
        throw error;
    }
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
