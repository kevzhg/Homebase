# Chat Notes

- Where is `liveWorkout.ts`?  
  Found at `src/liveWorkout.ts` (619 lines) and reviewed structure; overall project files: `app.ts`, `liveWorkout.ts`, `storage.ts`, `types.ts`, `server.ts`.

- Quick project review highlights  
  Frontend: `src/app.ts` main UI, `src/liveWorkout.ts` live session logic; `src/storage.ts` API/localStorage client; `src/types.ts` shared types. Backend: `src/server.ts` Express + MongoDB REST API. Default Mongo DB name is now `homebase`.

- How to run the server (local)  
  `npm install` → `npm run build:server` → `npm run server` (API defaults to `http://localhost:8000`). Frontend: `npm run build` → `npm start` (`http://localhost:3000`).

- How to run MongoDB  
  Either install MongoDB locally (service) or run via Docker `mongo:7` exposing `27017`. Test with `mongosh --eval "db.runCommand({ ping: 1 })"`.

- Rename project to Homebase  
  Updated `package.json` name, README title/path, default Mongo DB name to `homebase`; repo renamed on GitHub.

- Git push guidance  
  Commit/push commands to `master`; if SSH denied, switch remote to HTTPS `https://github.com/kevzhg/Homebase.git` or set up SSH key/agent and use `git@github.com:kevzhg/Homebase.git`.

- Create `workout` branch  
  `git checkout master && git pull origin master && git checkout -b workout && git push -u origin workout`.

- Deploy API to Render (uses Atlas)  
  Build: `npm install && npm run build:server`; start: `node dist-server/server.js`; envs: `MONGODB_URI=<Atlas SRV>`, `MONGODB_DB=homebase`, `PORT` provided by Render. Add CORS allowlist for `http://localhost:3000` and `https://kevzhg.github.io`.

- Atlas connection troubleshooting on Render  
  Whitelist IPs (or `0.0.0.0/0` for testing) in Atlas Network Access; ensure DB user/password correct; use Atlas “Drivers” SRV string with URL-encoded password, e.g. `mongodb+srv://kevzhg:<password>@<cluster>.mongodb.net/homebase?retryWrites=true&w=majority`.

- Root path “Cannot GET /”  
  Express has routes only under `/api/*`; optional to add `app.get('/')` if a root response is desired.

- GitHub Pages not working initially  
  Fixed by making API base configurable: `src/storage.ts` reads `window.API_BASE_URL` with localhost fallback. `index.html` sets `window.API_BASE_URL` to Render URL when on `github.io`. Rebuilt `dist`.

- Current environment mapping  
  - GitHub Pages (`kevzhg.github.io/Homebase`) → Render API `https://homebase-50dv.onrender.com/api` → Atlas.  
  - Local dev (`npm start` + `npm run server`) → `http://localhost:8000/api` → local Mongo (`mongodb://localhost:27017` by default).  
  - To use Render API from local frontend, set `window.API_BASE_URL` to the Render URL before loading. To run server against Atlas locally, export `MONGODB_URI=<Atlas SRV>` before `npm run server`.

- Notes on switching  
  Change `window.API_BASE_URL` (or rely on the `github.io` check) and rebuild for deploy. Adjust `MONGODB_URI`/`MONGODB_DB` envs to point the backend at local or cloud.

- Rename “workout” sessions to “training”  
  Frontend types and UI now use `Training` (with `TRAINING_TYPE_LABELS`), and CRUD client hits `/api/trainings`. Live training save uses `addTraining` and notes “Live training…”. Backend routes are `/api/trainings` with default Mongo collection `trainings` (env `MONGODB_COLLECTION_TRAININGS`). Templates/programs remain local.

- Local MongoDB run (user-level)  
  Started `mongod` with `data/mongodb` dbpath, `--bind_ip 127.0.0.1 --port 27017 --fork --logpath data/mongodb/mongod.log` (needed elevation in this environment). Verified with `mongosh --eval "db.runCommand({ ping: 1 })"`. Stop via `mongod --dbpath data/mongodb --shutdown`.

- README update  
  Added “Local setup: MongoDB quick start” section with the user-level `mongod` commands above and a note about using the system service (`sudo systemctl start mongod`) if binding is blocked.

- Frontend dashboard labels  
  Dashboard now reads “Today's Training Session” and “Recent Training Sessions” with matching empty-state text in `index.html`.

- Start command reminder  
  `npm start` serves the frontend; `npm run server` starts the API. `npm start server` fails because `serve` only accepts one path argument.

- Live Workout builder  
  Added a builder in `index.html`/`src/liveWorkout.ts` for Push/Pull/Legs sessions using the existing exercise library. You can create, clone, start, and delete workouts; pick exercises, sets, and reps; and start live sessions from the rendered program cards. Active workouts now start by program ID.

- Workout program data layer  
  `WorkoutProgram` types now include `updatedAt/source` plus Mongo-ready `WorkoutProgramDocument`/`WorkoutProgramInput`. Storage adds CRUD helpers (`add/update/clone/delete` programs) with a persistence stub ready for a future MongoDB-backed endpoint. Default programs seed if none exist.

- Live Workout edit & details  
  Program cards now include Details toggle listing exercises, plus Edit to load the builder for updates (with cancel/reset), alongside Start/Clone/Delete. Saving in edit mode calls `updateWorkoutProgram`; otherwise it creates a new program.

- Bug: Program details toggle opens wrong card (Details buttons only control leftmost workout); solution: added stable unique IDs for default/clone/add programs and dedupe when loading, so Details toggles target the correct card.

- Style request: Add styling to builder add button and set/rep display when adding an exercise; solution: builder list now shows set/rep chips, inputs/buttons aligned/padded, and builder inputs styled for consistent height.

- Bug: Removing an exercise in the builder Delete/Remove button does nothing; solution: set the remove button type to `button` and prevent default/bubbling in the click handler so the exercise now deletes properly.

- Layout request: Collapse Push/Pull/Legs and show created exercises when clicking a category; solution: program list now groups by category with collapsible headers (Push/Pull/Legs). Clicking a category expands its sessions grid; caret reflects state and remembers open categories during the session.

- Bug: Clicking one category opens all; solution: toggles now close other categories before opening the clicked one and reset caret states, keeping only one category expanded.

- Bug: Training Sessions accordion should toggle per category without affecting others; solution: category toggle now only opens/closes its own section and updates caret, persisting state in `expandedCategories` without touching other categories.

- UI redesign request: two-column builder + exercise library, new styling, chips, search, summary, saved trainings cards; solution implemented with new palette, fonts, segmented category control, searchable add row, library filters/quick add, summary bar, toast on save, and refreshed saved trainings layout/cards with details accordion kept.

- Request: Separate Build and Start training into different tabs, defaulting to Start; solution implemented with a tab bar (Start/Build). Start shows saved trainings by default; Build shows builder + library. Per-category accordion state kept; editing jumps to Build tab.

- Styling request: Modernize builder/library inputs; solution: inputs/selects/steppers/search now share 44px height, 10-12px rounding, soft #d7e3f4 borders, light backgrounds, muted placeholders, smooth hover/focus with accent glow; chips get hover polish.

- Styling request: Session name input and library category pills polished; solution: session name field now matches modern input (rounded, soft border, accent focus/hover) and library category chips are pill buttons with accent active state, hover lift, and focus ring.

- Feature: Exercise types + workout focus tags  
  Added `exerciseType` (Power/Hypertrophy/Compound/Flexibility/Cardio) to exercises (defaulting to Compound), displayed as pills in the exercise library with a new type filter bar. Saved program cards now show a focus chip and counts by type (dominant type via priority Power > Hypertrophy > Compound > Flexibility > Cardio). Library filters support both category (Push/Pull/Legs) and type. Types preserved across add/edit/clone. Styles updated for type chips/focus chip.

- Adjustment: Removed “Machine” equipment tags in exercise library metadata (Leg Press → Dumbbells, Leg Curls → Bands, Calf Raises → Dumbbells) to avoid machine-only gear.

- Request: Add provided warm-up and Push/Pull/Legs exercise list into exercise library/program defaults (with tags); solution: pending.
