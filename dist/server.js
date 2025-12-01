import express from 'express';
import cors from 'cors';
import { MongoClient, ObjectId } from 'mongodb';
import 'dotenv/config';
const app = express();
const PORT = Number(process.env.PORT || 8000);
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const MONGO_DB = process.env.MONGODB_DB || 'homebase';
const MONGO_COLLECTION = process.env.MONGODB_COLLECTION_TRAININGS
    || process.env.MONGODB_COLLECTION_WORKOUTS
    || 'trainings';
const MONGO_COLLECTION_MEALS = process.env.MONGODB_COLLECTION_MEALS || 'meals';
const MONGO_COLLECTION_WEIGHT = process.env.MONGODB_COLLECTION_WEIGHT || 'weight';
const MONGO_COLLECTION_ONIGIRI = process.env.MONGODB_COLLECTION_ONIGIRI || 'onigiri';
const MONGO_COLLECTION_PROGRAMS = process.env.MONGODB_COLLECTION_PROGRAMS || 'programs';
const MONGO_COLLECTION_EXERCISES = process.env.MONGODB_COLLECTION_EXERCISES || 'exercises';
const client = new MongoClient(MONGO_URI);
let trainingsCollection = null;
let mealsCollection = null;
let weightCollection = null;
let onigiriCollection = null;
let programsCollection = null;
let exercisesCollection = null;
async function connectDb() {
    if (!trainingsCollection) {
        await client.connect();
        const db = client.db(MONGO_DB);
        trainingsCollection = db.collection(MONGO_COLLECTION);
        mealsCollection = db.collection(MONGO_COLLECTION_MEALS);
        weightCollection = db.collection(MONGO_COLLECTION_WEIGHT);
        onigiriCollection = db.collection(MONGO_COLLECTION_ONIGIRI);
        programsCollection = db.collection(MONGO_COLLECTION_PROGRAMS);
        exercisesCollection = db.collection(MONGO_COLLECTION_EXERCISES);
        await trainingsCollection.createIndex({ date: 1 });
        await trainingsCollection.createIndex({ createdAt: -1 });
        await mealsCollection.createIndex({ date: 1 });
        await weightCollection.createIndex({ date: 1 });
        await onigiriCollection.createIndex({ id: 1 }, { unique: true });
        await programsCollection.createIndex({ id: 1 }, { unique: true });
        await programsCollection.createIndex({ updatedAt: -1 });
        await exercisesCollection.createIndex({ id: 1 }, { unique: true });
        await exercisesCollection.createIndex({ name: 1 });
    }
}
// Middleware
app.use(cors());
app.use(express.json());
app.use(async (_req, res, next) => {
    try {
        await connectDb();
        next();
    }
    catch (error) {
        console.error('Mongo connection error:', error);
        res.status(500).json({ message: 'Failed to connect to database' });
    }
});
// Helpers
function toResponse(doc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}
function mealToResponse(doc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}
function weightToResponse(doc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}
function onigiriToResponse(doc) {
    const { _id, ...rest } = doc;
    const serializeDate = (value) => {
        if (!value)
            return undefined;
        if (value instanceof Date)
            return value.toISOString();
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? undefined : parsed.toISOString();
    };
    return {
        id: rest.id,
        completion: rest.completion,
        updatedAt: serializeDate(rest.updatedAt),
        sections: (rest.sections || []).map(section => ({
            ...section,
            completion: section.completion,
            updatedAt: serializeDate(section.updatedAt),
            items: (section.items || []).map(item => ({
                ...item,
                completion: item.completion,
                updatedAt: serializeDate(item.updatedAt)
            }))
        }))
    };
}
function serializeDate(value) {
    if (!value)
        return undefined;
    if (value instanceof Date)
        return value.toISOString();
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? undefined : parsed.toISOString();
}
function programToResponse(doc) {
    const { _id, ...rest } = doc;
    const id = rest.id || _id?.toString() || new ObjectId().toHexString();
    return {
        ...rest,
        id,
        createdAt: serializeDate(rest.createdAt) ?? new Date().toISOString(),
        updatedAt: serializeDate(rest.updatedAt) ?? undefined
    };
}
function exerciseToResponse(doc) {
    const { _id, ...rest } = doc;
    return {
        ...rest,
        id: rest.id || _id?.toString() || new ObjectId().toHexString(),
        createdAt: serializeDate(rest.createdAt) ?? new Date().toISOString(),
        updatedAt: serializeDate(rest.updatedAt) ?? undefined
    };
}
function parseId(id) {
    try {
        return new ObjectId(id);
    }
    catch {
        return null;
    }
}
function normalizeWeight(weight) {
    if (typeof weight === 'number' && Number.isFinite(weight) && weight > 0) {
        return weight;
    }
    return 1;
}
function calculateSectionCompletion(section) {
    const items = section.items || [];
    if (items.length === 0)
        return 0;
    const totalWeight = items.reduce((sum, item) => sum + normalizeWeight(item.weight), 0);
    if (totalWeight <= 0)
        return 0;
    const completedWeight = items.reduce((sum, item) => sum + (item.done ? normalizeWeight(item.weight) : 0), 0);
    return completedWeight / totalWeight;
}
function calculatePlannerCompletion(sections) {
    if (sections.length === 0)
        return 0;
    const totalWeight = sections.reduce((sum, section) => sum + normalizeWeight(section.weight), 0);
    if (totalWeight <= 0)
        return 0;
    const weightedSum = sections.reduce((sum, section) => sum + normalizeWeight(section.weight) * (section.completion ?? 0), 0);
    return weightedSum / totalWeight;
}
function normalizeItemPayload(raw, now) {
    if (!raw.id || typeof raw.id !== 'string')
        return null;
    if (!raw.title || typeof raw.title !== 'string')
        return null;
    const updatedAt = raw.updatedAt instanceof Date ? raw.updatedAt : new Date(raw.updatedAt ?? now);
    return {
        id: raw.id,
        title: raw.title,
        notes: raw.notes ?? '',
        weight: normalizeWeight(raw.weight),
        done: Boolean(raw.done),
        completion: raw.done ? 1 : 0,
        updatedAt: Number.isNaN(updatedAt.getTime()) ? now : updatedAt
    };
}
function normalizeSectionPayload(raw, now) {
    if (!raw.id || typeof raw.id !== 'string')
        return null;
    if (!raw.name || typeof raw.name !== 'string')
        return null;
    const items = [];
    for (const item of raw.items || []) {
        const normalized = normalizeItemPayload(item, now);
        if (!normalized)
            return null;
        items.push(normalized);
    }
    const updatedAt = raw.updatedAt instanceof Date ? raw.updatedAt : new Date(raw.updatedAt ?? now);
    const section = {
        id: raw.id,
        name: raw.name,
        weight: normalizeWeight(raw.weight),
        items,
        updatedAt: Number.isNaN(updatedAt.getTime()) ? now : updatedAt
    };
    section.completion = calculateSectionCompletion(section);
    return section;
}
function buildPlannerDoc(payload, existing) {
    if (!payload.id || typeof payload.id !== 'string')
        return null;
    const now = new Date();
    const sections = [];
    for (const section of payload.sections || []) {
        const normalized = normalizeSectionPayload(section, now);
        if (!normalized)
            return null;
        sections.push(normalized);
    }
    const updatedAt = payload.updatedAt instanceof Date ? payload.updatedAt : new Date(payload.updatedAt ?? now);
    const createdAt = payload.createdAt instanceof Date ? payload.createdAt : new Date(payload.createdAt ?? existing?.createdAt ?? now);
    const doc = {
        id: payload.id,
        sections,
        createdAt: Number.isNaN(createdAt.getTime()) ? now : createdAt,
        updatedAt: Number.isNaN(updatedAt.getTime()) ? now : updatedAt
    };
    doc.completion = calculatePlannerCompletion(doc.sections);
    if (existing && existing._id) {
        doc._id = existing._id;
    }
    return doc;
}
function findProgramFilter(id) {
    const objId = parseId(id);
    if (objId) {
        return { $or: [{ id }, { _id: objId }] };
    }
    return { id };
}
// Exercises
app.get('/api/exercises', async (_req, res) => {
    if (!exercisesCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await exercisesCollection.find().sort({ name: 1 }).toArray();
    res.json(docs.map(exerciseToResponse));
});
app.get('/api/exercises/:id', async (req, res) => {
    if (!exercisesCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const doc = await exercisesCollection.findOne(filter);
    if (!doc)
        return res.status(404).json({ message: 'Exercise not found' });
    res.json(exerciseToResponse(doc));
});
app.post('/api/exercises', async (req, res) => {
    if (!exercisesCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const payload = req.body;
    const doc = normalizeExercisePayload(payload);
    if (!doc)
        return res.status(400).json({ message: 'Invalid exercise payload' });
    await exercisesCollection.updateOne({ id: doc.id }, { $set: doc }, { upsert: true });
    const saved = await exercisesCollection.findOne({ id: doc.id });
    res.status(201).json(exerciseToResponse(saved || doc));
});
app.put('/api/exercises/:id', async (req, res) => {
    if (!exercisesCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const existing = await exercisesCollection.findOne(filter);
    if (!existing)
        return res.status(404).json({ message: 'Exercise not found' });
    const payload = req.body;
    const doc = normalizeExercisePayload(payload, existing);
    if (!doc)
        return res.status(400).json({ message: 'Invalid exercise payload' });
    await exercisesCollection.updateOne(filter, { $set: doc });
    const saved = await exercisesCollection.findOne(filter);
    res.json(exerciseToResponse(saved || doc));
});
app.delete('/api/exercises/:id', async (req, res) => {
    if (!exercisesCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const result = await exercisesCollection.deleteOne(filter);
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Exercise not found' });
    res.status(204).send();
});
function normalizeProgramExercises(exercises) {
    const normalized = [];
    if (!Array.isArray(exercises))
        return normalized;
    exercises.forEach((ex, idx) => {
        if (!ex || !ex.name)
            return;
        const id = typeof ex.id === 'string' && ex.id.trim()
            ? ex.id
            : `exercise-${Date.now().toString(36)}-${idx}`;
        const sets = Number(ex.sets);
        const restTime = Number(ex.restTime);
        normalized.push({
            id,
            name: String(ex.name),
            sets: Number.isFinite(sets) && sets > 0 ? sets : 1,
            reps: ex.reps ?? '',
            restTime: Number.isFinite(restTime) && restTime >= 0 ? restTime : 0,
            notes: ex.notes,
            exerciseType: ex.exerciseType
        });
    });
    return normalized;
}
function normalizeExercisePayload(payload, existing) {
    if (!payload.name || typeof payload.name !== 'string')
        return null;
    const now = new Date();
    const id = payload.id || existing?.id || new ObjectId().toHexString();
    const categoryRaw = typeof payload.category === 'string' ? payload.category : existing?.category || 'push';
    const category = ['push', 'pull', 'legs'].includes(categoryRaw) ? categoryRaw : 'push';
    const muscles = Array.isArray(payload.muscles)
        ? payload.muscles.map(m => String(m)).filter(Boolean)
        : existing?.muscles || [];
    const equipment = payload.equipment ? String(payload.equipment) : existing?.equipment;
    const exerciseType = payload.exerciseType ? String(payload.exerciseType) : existing?.exerciseType;
    const sets = payload.sets ?? existing?.sets;
    const reps = payload.reps ?? existing?.reps;
    const restTime = payload.restTime ?? existing?.restTime;
    const doc = {
        id,
        name: payload.name,
        category,
        muscles,
        equipment,
        exerciseType,
        sets: typeof sets === 'number' && Number.isFinite(sets) && sets > 0 ? sets : undefined,
        reps: typeof reps === 'number' || typeof reps === 'string' ? reps : undefined,
        restTime: typeof restTime === 'number' && Number.isFinite(restTime) && restTime >= 0 ? restTime : undefined,
        createdAt: existing?.createdAt || now,
        updatedAt: now
    };
    if (existing && existing._id) {
        doc._id = existing._id;
    }
    return doc;
}
// Workout Programs
app.get('/api/programs', async (_req, res) => {
    if (!programsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await programsCollection.find().sort({ updatedAt: -1, createdAt: -1 }).toArray();
    res.json(docs.map(programToResponse));
});
app.get('/api/programs/:id', async (req, res) => {
    if (!programsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const doc = await programsCollection.findOne(filter);
    if (!doc)
        return res.status(404).json({ message: 'Program not found' });
    res.json(programToResponse(doc));
});
app.post('/api/programs', async (req, res) => {
    if (!programsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const payload = req.body;
    const now = new Date();
    const exercises = normalizeProgramExercises(payload.exercises);
    const doc = {
        ...payload,
        exercises,
        id: payload.id || new ObjectId().toHexString(),
        createdAt: payload.createdAt ? new Date(payload.createdAt) : now,
        updatedAt: now,
        source: payload.source ?? 'api'
    };
    await programsCollection.updateOne({ id: doc.id }, { $set: doc }, { upsert: true });
    const saved = await programsCollection.findOne({ id: doc.id });
    res.status(201).json(programToResponse(saved || doc));
});
app.put('/api/programs/:id', async (req, res) => {
    if (!programsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const updates = req.body;
    updates.updatedAt = new Date();
    if (updates.exercises) {
        updates.exercises = normalizeProgramExercises(updates.exercises);
    }
    const updated = await programsCollection.findOneAndUpdate(filter, { $set: updates }, { returnDocument: 'after' });
    if (!updated)
        return res.status(404).json({ message: 'Program not found' });
    res.json(programToResponse(updated));
});
app.delete('/api/programs/:id', async (req, res) => {
    if (!programsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const filter = findProgramFilter(req.params.id);
    const result = await programsCollection.deleteOne(filter);
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Program not found' });
    res.status(204).send();
});
// Routes (trainings + backward-compatible workouts alias)
app.get('/api/trainings', async (_req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await trainingsCollection.find().sort({ createdAt: -1 }).toArray();
    res.json(docs.map(toResponse));
});
app.get('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const doc = await trainingsCollection.findOne({ _id: objId });
    if (!doc)
        return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(doc));
});
app.post('/api/trainings', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const training = req.body;
    const now = new Date();
    const doc = {
        ...training,
        createdAt: now,
        updatedAt: now
    };
    const result = await trainingsCollection.insertOne(doc);
    const inserted = await trainingsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? toResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});
app.put('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const updates = req.body;
    updates.updatedAt = new Date();
    const updated = await trainingsCollection.findOneAndUpdate({ _id: objId }, { $set: updates }, { returnDocument: 'after' });
    if (!updated)
        return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(updated));
});
app.delete('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const result = await trainingsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Training not found' });
    res.status(204).send();
});
// Legacy workout routes (alias to trainings)
app.get('/api/workouts', async (_req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await trainingsCollection.find().sort({ createdAt: -1 }).toArray();
    res.json(docs.map(toResponse));
});
app.get('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const doc = await trainingsCollection.findOne({ _id: objId });
    if (!doc)
        return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(doc));
});
app.post('/api/workouts', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const training = req.body;
    const now = new Date();
    const doc = { ...training, createdAt: now, updatedAt: now };
    const result = await trainingsCollection.insertOne(doc);
    const inserted = await trainingsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? toResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});
app.put('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const updates = req.body;
    updates.updatedAt = new Date();
    const updated = await trainingsCollection.findOneAndUpdate({ _id: objId }, { $set: updates }, { returnDocument: 'after' });
    if (!updated)
        return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(updated));
});
app.delete('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const result = await trainingsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Training not found' });
    res.status(204).send();
});
// Meals
app.get('/api/meals', async (_req, res) => {
    if (!mealsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await mealsCollection.find().sort({ date: -1 }).toArray();
    res.json(docs.map(mealToResponse));
});
app.post('/api/meals', async (req, res) => {
    if (!mealsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const meal = req.body;
    const now = new Date();
    const doc = { ...meal, createdAt: now, updatedAt: now };
    const result = await mealsCollection.insertOne(doc);
    const inserted = await mealsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? mealToResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});
app.put('/api/meals/:id', async (req, res) => {
    if (!mealsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const updates = req.body;
    updates.updatedAt = new Date();
    const updated = await mealsCollection.findOneAndUpdate({ _id: objId }, { $set: updates }, { returnDocument: 'after' });
    if (!updated)
        return res.status(404).json({ message: 'Meal not found' });
    res.json(mealToResponse(updated));
});
app.delete('/api/meals/:id', async (req, res) => {
    if (!mealsCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const result = await mealsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Meal not found' });
    res.status(204).send();
});
// Weight
app.get('/api/weight', async (_req, res) => {
    if (!weightCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const docs = await weightCollection.find().sort({ date: -1 }).toArray();
    res.json(docs.map(weightToResponse));
});
app.post('/api/weight', async (req, res) => {
    if (!weightCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const entry = req.body;
    const now = new Date();
    const doc = { ...entry, createdAt: now, updatedAt: now };
    const result = await weightCollection.insertOne(doc);
    const inserted = await weightCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? weightToResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});
app.put('/api/weight/:id', async (req, res) => {
    if (!weightCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const updates = req.body;
    updates.updatedAt = new Date();
    const updated = await weightCollection.findOneAndUpdate({ _id: objId }, { $set: updates }, { returnDocument: 'after' });
    if (!updated)
        return res.status(404).json({ message: 'Weight entry not found' });
    res.json(weightToResponse(updated));
});
app.delete('/api/weight/:id', async (req, res) => {
    if (!weightCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId)
        return res.status(400).json({ message: 'Invalid id' });
    const result = await weightCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0)
        return res.status(404).json({ message: 'Weight entry not found' });
    res.status(204).send();
});
// Onigiri Planner
app.get('/api/onigiri', async (_req, res) => {
    if (!onigiriCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const existing = await onigiriCollection.findOne({});
    if (!existing) {
        const now = new Date();
        const doc = {
            id: new ObjectId().toHexString(),
            sections: [],
            completion: 0,
            createdAt: now,
            updatedAt: now
        };
        const result = await onigiriCollection.insertOne(doc);
        return res.json(onigiriToResponse({ ...doc, _id: result.insertedId }));
    }
    res.json(onigiriToResponse(existing));
});
app.put('/api/onigiri', async (req, res) => {
    if (!onigiriCollection)
        return res.status(500).json({ message: 'DB not initialized' });
    const payload = req.body;
    const existing = payload.id
        ? await onigiriCollection.findOne({ id: payload.id })
        : await onigiriCollection.findOne({});
    const doc = buildPlannerDoc(payload, existing || undefined);
    if (!doc)
        return res.status(400).json({ message: 'Invalid payload for Onigiri planner' });
    await onigiriCollection.updateOne({ id: doc.id }, { $set: doc }, { upsert: true });
    const saved = await onigiriCollection.findOne({ id: doc.id });
    res.json(onigiriToResponse(saved || doc));
});
app.listen(PORT, () => {
    console.log(`🚀 Server is running at http://localhost:${PORT}`);
});
//# sourceMappingURL=server.js.map