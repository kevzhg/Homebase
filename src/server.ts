import express from 'express';
import cors from 'cors';
import { MongoClient, ObjectId, Collection } from 'mongodb';
import 'dotenv/config';

// Types local to the server (aligned with frontend types but isolated here)
interface TrainingSetEntry {
    setNumber: number;
    weight?: number;
    reps?: number | string;
    completed: boolean;
    completedAt?: string;
}

interface TrainingExerciseEntry {
    exerciseId: string;
    name: string;
    notes?: string;
    elapsedMs?: number;
    sets: TrainingSetEntry[];
}

interface TrainingDoc {
    _id?: ObjectId;
    date: string;
    type: string;
    durationMinutes: number;
    programName?: string;
    exercises: TrainingExerciseEntry[];
    notes?: string;
    createdAt?: Date;
    updatedAt?: Date;
}

interface MealDoc {
    _id?: ObjectId;
    date: string;
    type: string;
    name: string;
    calories?: number;
    protein?: number;
    description?: string;
    createdAt?: Date;
    updatedAt?: Date;
}

interface WeightDoc {
    _id?: ObjectId;
    date: string;
    weight: number;
    unit: string;
    notes?: string;
    createdAt?: Date;
    updatedAt?: Date;
}

const app = express();
const PORT = Number(process.env.PORT || 8000);

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const MONGO_DB = process.env.MONGODB_DB || 'homebase';
const MONGO_COLLECTION = process.env.MONGODB_COLLECTION_TRAININGS
    || process.env.MONGODB_COLLECTION_WORKOUTS
    || 'trainings';
const MONGO_COLLECTION_MEALS = process.env.MONGODB_COLLECTION_MEALS || 'meals';
const MONGO_COLLECTION_WEIGHT = process.env.MONGODB_COLLECTION_WEIGHT || 'weight';

const client = new MongoClient(MONGO_URI);
let trainingsCollection: Collection<TrainingDoc> | null = null;
let mealsCollection: Collection<MealDoc> | null = null;
let weightCollection: Collection<WeightDoc> | null = null;

async function connectDb(): Promise<void> {
    if (!trainingsCollection) {
        await client.connect();
        const db = client.db(MONGO_DB);
        trainingsCollection = db.collection<TrainingDoc>(MONGO_COLLECTION);
        mealsCollection = db.collection<MealDoc>(MONGO_COLLECTION_MEALS);
        weightCollection = db.collection<WeightDoc>(MONGO_COLLECTION_WEIGHT);
        await trainingsCollection.createIndex({ date: 1 });
        await trainingsCollection.createIndex({ createdAt: -1 });
        await mealsCollection!.createIndex({ date: 1 });
        await weightCollection!.createIndex({ date: 1 });
    }
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(async (_req, res, next) => {
    try {
        await connectDb();
        next();
    } catch (error) {
        console.error('Mongo connection error:', error);
        res.status(500).json({ message: 'Failed to connect to database' });
    }
});

// Helpers
function toResponse(doc: TrainingDoc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}

function mealToResponse(doc: MealDoc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}

function weightToResponse(doc: WeightDoc) {
    const { _id, ...rest } = doc;
    return { id: _id?.toString(), ...rest };
}

function parseId(id: string): ObjectId | null {
    try {
        return new ObjectId(id);
    } catch {
        return null;
    }
}

// Routes (trainings + backward-compatible workouts alias)
app.get('/api/trainings', async (_req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const docs = await trainingsCollection.find().sort({ createdAt: -1 }).toArray();
    res.json(docs.map(toResponse));
});

app.get('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const doc = await trainingsCollection.findOne({ _id: objId });
    if (!doc) return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(doc));
});

app.post('/api/trainings', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const training = req.body as TrainingDoc;
    const now = new Date();
    const doc: TrainingDoc = {
        ...training,
        createdAt: now,
        updatedAt: now
    };

    const result = await trainingsCollection.insertOne(doc);
    const inserted = await trainingsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? toResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});

app.put('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const updates = req.body as Partial<TrainingDoc>;
    updates.updatedAt = new Date();

    const updated = await trainingsCollection.findOneAndUpdate(
        { _id: objId },
        { $set: updates },
        { returnDocument: 'after' }
    );

    if (!updated) return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(updated));
});

app.delete('/api/trainings/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const result = await trainingsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Training not found' });
    res.status(204).send();
});

// Legacy workout routes (alias to trainings)
app.get('/api/workouts', async (_req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const docs = await trainingsCollection.find().sort({ createdAt: -1 }).toArray();
    res.json(docs.map(toResponse));
});

app.get('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const doc = await trainingsCollection.findOne({ _id: objId });
    if (!doc) return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(doc));
});

app.post('/api/workouts', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const training = req.body as TrainingDoc;
    const now = new Date();
    const doc: TrainingDoc = { ...training, createdAt: now, updatedAt: now };

    const result = await trainingsCollection.insertOne(doc);
    const inserted = await trainingsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? toResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});

app.put('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const updates = req.body as Partial<TrainingDoc>;
    updates.updatedAt = new Date();

    const updated = await trainingsCollection.findOneAndUpdate(
        { _id: objId },
        { $set: updates },
        { returnDocument: 'after' }
    );

    if (!updated) return res.status(404).json({ message: 'Training not found' });
    res.json(toResponse(updated));
});

app.delete('/api/workouts/:id', async (req, res) => {
    if (!trainingsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const result = await trainingsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Training not found' });
    res.status(204).send();
});

// Meals
app.get('/api/meals', async (_req, res) => {
    if (!mealsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const docs = await mealsCollection.find().sort({ date: -1 }).toArray();
    res.json(docs.map(mealToResponse));
});

app.post('/api/meals', async (req, res) => {
    if (!mealsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const meal = req.body as MealDoc;
    const now = new Date();
    const doc: MealDoc = { ...meal, createdAt: now, updatedAt: now };
    const result = await mealsCollection.insertOne(doc);
    const inserted = await mealsCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? mealToResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});

app.put('/api/meals/:id', async (req, res) => {
    if (!mealsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const updates = req.body as Partial<MealDoc>;
    updates.updatedAt = new Date();

    const updated = await mealsCollection.findOneAndUpdate(
        { _id: objId },
        { $set: updates },
        { returnDocument: 'after' }
    );

    if (!updated) return res.status(404).json({ message: 'Meal not found' });
    res.json(mealToResponse(updated));
});

app.delete('/api/meals/:id', async (req, res) => {
    if (!mealsCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const result = await mealsCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Meal not found' });
    res.status(204).send();
});

// Weight
app.get('/api/weight', async (_req, res) => {
    if (!weightCollection) return res.status(500).json({ message: 'DB not initialized' });
    const docs = await weightCollection.find().sort({ date: -1 }).toArray();
    res.json(docs.map(weightToResponse));
});

app.post('/api/weight', async (req, res) => {
    if (!weightCollection) return res.status(500).json({ message: 'DB not initialized' });
    const entry = req.body as WeightDoc;
    const now = new Date();
    const doc: WeightDoc = { ...entry, createdAt: now, updatedAt: now };
    const result = await weightCollection.insertOne(doc);
    const inserted = await weightCollection.findOne({ _id: result.insertedId });
    res.status(201).json(inserted ? weightToResponse(inserted) : { id: result.insertedId.toString(), ...doc });
});

app.put('/api/weight/:id', async (req, res) => {
    if (!weightCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const updates = req.body as Partial<WeightDoc>;
    updates.updatedAt = new Date();

    const updated = await weightCollection.findOneAndUpdate(
        { _id: objId },
        { $set: updates },
        { returnDocument: 'after' }
    );

    if (!updated) return res.status(404).json({ message: 'Weight entry not found' });
    res.json(weightToResponse(updated));
});

app.delete('/api/weight/:id', async (req, res) => {
    if (!weightCollection) return res.status(500).json({ message: 'DB not initialized' });
    const objId = parseId(req.params.id);
    if (!objId) return res.status(400).json({ message: 'Invalid id' });

    const result = await weightCollection.deleteOne({ _id: objId });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Weight entry not found' });
    res.status(204).send();
});

app.listen(PORT, () => {
    console.log(`🚀 Server is running at http://localhost:${PORT}`);
});
