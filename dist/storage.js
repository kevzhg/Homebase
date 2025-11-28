const ACTIVE_WORKOUT_KEY = 'fitness-tracker-active-workout';
// Allow overriding the API base URL via a global for prod (GitHub Pages) while keeping localhost as the dev default.
const API_BASE_URL = (typeof window !== 'undefined' && window.API_BASE_URL) || 'http://localhost:8000/api';
// This will hold all data fetched from the server
let db = { workouts: [], meals: [], weight: [] };
/**
 * Fetches workouts, meals, and weight entries from the server and populates the local 'db' object.
 * This should be called once when the app starts.
 */
export async function initStorage() {
    try {
        const [workouts, meals, weight] = await Promise.all([
            apiGet('workouts'),
            apiGet('meals'),
            apiGet('weight')
        ]);
        db.workouts = workouts.map(normalizeWorkout);
        db.meals = meals.map(normalizeMeal);
        db.weight = weight.map(normalizeWeight);
        console.log('Database initialized from server', db);
    }
    catch (error) {
        console.error("Error initializing storage:", error);
        // Initialize with empty structure if server fails
        db = { workouts: [], meals: [], weight: [] };
    }
}
// --- Generic API Functions ---
async function apiGet(endpoint) {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`);
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API GET to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
    return response.json();
}
async function apiPost(endpoint, data) {
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
async function apiPut(endpoint, data) {
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
async function apiDelete(endpoint) {
    const response = await fetch(`${API_BASE_URL}/${endpoint}`, { method: 'DELETE' });
    if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`API DELETE to ${endpoint} failed: ${response.status} ${errorBody}`);
    }
}
// Convert backend _id to id to keep frontend consistent
function normalizeWorkout(raw) {
    const id = raw.id ?? raw._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete cleaned._id;
    return cleaned;
}
function normalizeMeal(raw) {
    const id = raw.id ?? raw._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete cleaned._id;
    return cleaned;
}
function normalizeWeight(raw) {
    const id = raw.id ?? raw._id;
    const cleaned = { ...raw, id: id ? String(id) : undefined };
    delete cleaned._id;
    return cleaned;
}
// --- Workout Management ---
export const getWorkouts = () => db.workouts;
export const getWorkoutsByDate = (date) => db.workouts.filter(w => w.date === date);
export const getWorkoutById = (id) => db.workouts.find(w => w.id === id);
export async function addWorkout(workoutData) {
    try {
        const payload = { ...workoutData };
        delete payload.id;
        delete payload._id;
        const newWorkout = normalizeWorkout(await apiPost('workouts', payload));
        db.workouts.push(newWorkout);
        console.log('Workout saved successfully via API');
    }
    catch (error) {
        console.error('Error in addWorkout:', error);
        alert('Could not save workout. Please check the server connection and try again.');
        throw error; // Re-throw to stop calling function
    }
}
export async function updateWorkout(id, updates) {
    try {
        const payload = { ...updates };
        delete payload.id;
        delete payload._id;
        const updated = normalizeWorkout(await apiPut(`workouts/${id}`, payload));
        db.workouts = db.workouts.map(w => w.id === id ? updated : w);
        return updated;
    }
    catch (error) {
        console.error('Error in updateWorkout:', error);
        alert('Could not update workout. Please check the server connection and try again.');
        return null;
    }
}
export async function deleteWorkout(id) {
    try {
        await apiDelete(`workouts/${id}`);
        db.workouts = db.workouts.filter(w => w.id !== id);
    }
    catch (error) {
        console.error('Error in deleteWorkout:', error);
        alert('Could not delete workout. Please check the server connection and try again.');
        throw error;
    }
}
// --- Meal Management ---
export const getMeals = () => db.meals;
export const getMealsByDate = (date) => db.meals.filter(m => m.date === date);
export async function addMeal(mealData) {
    try {
        const payload = { ...mealData };
        delete payload.id;
        delete payload._id;
        const newMeal = normalizeMeal(await apiPost('meals', payload));
        db.meals.push(newMeal);
    }
    catch (error) {
        console.error('Error in addMeal:', error);
        alert('Could not save meal. Please check the server connection and try again.');
        throw error;
    }
}
export async function deleteMeal(id) {
    try {
        await apiDelete(`meals/${id}`);
        db.meals = db.meals.filter(m => m.id !== id);
    }
    catch (error) {
        console.error('Error in deleteMeal:', error);
        alert('Could not delete meal. Please check the server connection and try again.');
        throw error;
    }
}
// --- Weight Management ---
export const getWeightEntries = () => db.weight;
export const getWeightByDate = (date) => db.weight.find(w => w.date === date);
export async function addWeightEntry(weightData) {
    try {
        const payload = { ...weightData };
        delete payload.id;
        delete payload._id;
        const newWeight = normalizeWeight(await apiPost('weight', payload));
        db.weight.push(newWeight);
    }
    catch (error) {
        console.error('Error in addWeightEntry:', error);
        alert('Could not save weight entry. Please check the server connection and try again.');
        throw error;
    }
}
export async function deleteWeightEntry(id) {
    try {
        await apiDelete(`weight/${id}`);
        db.weight = db.weight.filter(w => w.id !== id);
    }
    catch (error) {
        console.error('Error in deleteWeightEntry:', error);
        alert('Could not delete weight entry. Please check the server connection and try again.');
        throw error;
    }
}
// --- Workout Program Management (uses localStorage) ---
// These are fine to keep in localStorage as they are more like app configuration.
export function getWorkoutPrograms() {
    const data = localStorage.getItem('fitness-tracker-programs');
    return data ? JSON.parse(data) : [];
}
export function getWorkoutProgramById(id) {
    return getWorkoutPrograms().find(p => p.id === id);
}
export async function addWorkoutProgram(programData) {
    const programs = getWorkoutPrograms();
    const newProgram = {
        ...programData,
        id: `program-${Date.now()}`,
        createdAt: new Date().toISOString()
    };
    programs.push(newProgram);
    localStorage.setItem('fitness-tracker-programs', JSON.stringify(programs));
}
// --- Active Workout Management (uses localStorage) ---
// This is session state, so localStorage is the perfect place for it.
export function getActiveWorkout() {
    try {
        const data = localStorage.getItem(ACTIVE_WORKOUT_KEY);
        return data ? JSON.parse(data) : null;
    }
    catch (error) {
        console.error('Error getting active workout:', error);
        return null;
    }
}
export function saveActiveWorkout(workout) {
    localStorage.setItem(ACTIVE_WORKOUT_KEY, JSON.stringify(workout));
}
export function clearActiveWorkout() {
    localStorage.removeItem(ACTIVE_WORKOUT_KEY);
}
//# sourceMappingURL=storage.js.map