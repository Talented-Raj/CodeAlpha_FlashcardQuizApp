const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;
const DB_FILE = path.join(__dirname, 'database.json');

app.use(cors());
app.use(bodyParser.json());

// Load or initialize DB
let db = {
  flashcards: [],
  study_logs: []
};

const defaultCards = [
  {
    id: 1,
    question: 'What is an Abstract Class?',
    answer: 'A class that cannot be instantiated directly and serves as a blueprint for other subclasses. It can contain abstract methods (methods without a body) that must be implemented by subclasses.',
    category: 'Programming',
    difficulty: 'Medium',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 2,
    question: 'What is recursion?',
    answer: 'A programming methodology where a function calls itself directly or indirectly to solve a larger problem by breaking it down into smaller, manageable subproblems.',
    category: 'Programming',
    difficulty: 'Medium',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 3,
    question: 'What is the difference between final and const in Dart?',
    answer: '\'final\' variables are set once and initialized at runtime, whereas \'const\' variables are compile-time constants initialized at compilation time.',
    category: 'Programming',
    difficulty: 'Easy',
    favorite: 1,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 4,
    question: 'What is the Pythagorean Theorem?',
    answer: 'In a right-angled triangle, the square of the hypotenuse is equal to the sum of the squares of the other two sides (a² + b² = c²).',
    category: 'Mathematics',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 5,
    question: 'What is a Prime Number?',
    answer: 'A natural number greater than 1 that has no positive divisors other than 1 and itself (e.g., 2, 3, 5, 7, 11).',
    category: 'Mathematics',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 6,
    question: 'What is Euler\'s Formula?',
    answer: 'A mathematical formula in complex analysis: e^(iθ) = cos(θ) + i sin(θ). For θ = π, it yields the famous identity e^(iπ) + 1 = 0.',
    category: 'Mathematics',
    difficulty: 'Hard',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 7,
    question: 'What is Photosynthesis?',
    answer: 'The biological process used by plants, algae, and some bacteria to transform solar light energy into chemical energy (glucose) using carbon dioxide and water.',
    category: 'Science',
    difficulty: 'Medium',
    favorite: 1,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 8,
    question: 'What is the speed of light in a vacuum?',
    answer: 'Approximately 299,792,458 meters per second (about 3.00 × 10⁸ m/s or 186,000 miles per second).',
    category: 'Science',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 9,
    question: 'What is Newton\'s Third Law of Motion?',
    answer: 'For every action, there is an equal and opposite reaction. It states that forces always occur in matched interaction pairs.',
    category: 'Science',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 10,
    question: 'When did World War II begin?',
    answer: 'September 1, 1939, with the invasion of Poland by Nazi Germany, prompting declarations of war by Britain and France.',
    category: 'History',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 11,
    question: 'What was the Magna Carta?',
    answer: 'A royal charter of rights agreed to by King John of England in 1215, establishing the legal principle that everyone, including the monarch, is subject to the rule of law.',
    category: 'History',
    difficulty: 'Hard',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 12,
    question: 'Who was the first President of the United States?',
    answer: 'George Washington, who served from 1789 to 1797 and is historically honored as the father of his country.',
    category: 'History',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 13,
    question: 'What is a metaphor?',
    answer: 'A figure of speech that makes a direct comparative reference between two unrelated things without using comparative words like \'like\' or \'as\' (e.g., \'Time is a thief\').',
    category: 'English',
    difficulty: 'Easy',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 14,
    question: 'What does the word \'diligent\' mean?',
    answer: 'Showing care, conscientiousness, and persistent, hard-working effort in carrying out one\'s work, assignments, or duties.',
    category: 'English',
    difficulty: 'Medium',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 15,
    question: 'What is the difference between active and passive voice?',
    answer: 'In active voice, the subject performs the action (e.g., \'The dog chased the cat\'). In passive voice, the subject receives the action (e.g., \'The cat was chased by the dog\').',
    category: 'English',
    difficulty: 'Medium',
    favorite: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

function readDB() {
  try {
    if (fs.existsSync(DB_FILE)) {
      const data = fs.readFileSync(DB_FILE, 'utf8');
      db = JSON.parse(data);
    } else {
      db = {
        flashcards: [...defaultCards],
        study_logs: []
      };
      writeDB();
    }
  } catch (e) {
    console.error('Error reading database file, using in-memory fallback', e);
  }
}

function writeDB() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('Error writing to database file', e);
  }
}

// Initial DB load
readDB();

// API Routes

// 1. Reset Database
app.post('/api/reset', (req, res) => {
  db = {
    flashcards: [...defaultCards],
    study_logs: []
  };
  writeDB();
  res.json({ success: true, message: 'Database reset successfully' });
});

// 2. Get categories
app.get('/api/categories', (req, res) => {
  const categories = [...new Set(db.flashcards.map(c => c.category))].sort();
  res.json(categories);
});

// 3. Search flashcards
app.get('/api/flashcards/search', (req, res) => {
  const query = (req.query.q || '').toLowerCase();
  const results = db.flashcards.filter(c => 
    c.question.toLowerCase().includes(query) ||
    c.answer.toLowerCase().includes(query) ||
    c.category.toLowerCase().includes(query)
  ).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  res.json(results);
});

// 4. Get flashcards (supports filter & sorting)
app.get('/api/flashcards', (req, res) => {
  let cards = [...db.flashcards];

  const category = req.query.category;
  const favorite = req.query.favorite;
  const sortBy = req.query.sortBy || 'createdAt';
  const sortAscending = req.query.sortAscending === 'true';

  if (category) {
    cards = cards.filter(c => c.category === category);
  }
  if (favorite !== undefined) {
    const favInt = favorite === 'true' ? 1 : 0;
    cards = cards.filter(c => c.favorite === favInt);
  }

  // Sort
  cards.sort((a, b) => {
    let valA = a[sortBy];
    let valB = b[sortBy];
    
    if (sortBy === 'createdAt' || sortBy === 'updatedAt') {
      valA = new Date(valA);
      valB = new Date(valB);
    } else if (typeof valA === 'string') {
      valA = valA.toLowerCase();
      valB = valB.toLowerCase();
    }

    if (valA < valB) return sortAscending ? -1 : 1;
    if (valA > valB) return sortAscending ? 1 : -1;
    return 0;
  });

  res.json(cards);
});

// 5. Get flashcard by ID
app.get('/api/flashcards/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const card = db.flashcards.find(c => c.id === id);
  if (card) {
    res.json(card);
  } else {
    res.status(404).json({ error: 'Flashcard not found' });
  }
});

// 6. Create flashcard
app.post('/api/flashcards', (req, res) => {
  const { question, answer, category, difficulty, favorite } = req.body;
  
  if (!question || !answer || !category) {
    return res.status(400).json({ error: 'Missing required fields: question, answer, category' });
  }

  const maxId = db.flashcards.reduce((max, c) => c.id > max ? c.id : max, 0);
  
  const newCard = {
    id: maxId + 1,
    question,
    answer,
    category,
    difficulty: difficulty || 'Medium',
    favorite: favorite ? 1 : 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  db.flashcards.push(newCard);
  writeDB();
  res.status(201).json(newCard);
});

// 7. Update flashcard
app.put('/api/flashcards/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const index = db.flashcards.findIndex(c => c.id === id);

  if (index === -1) {
    return res.status(404).json({ error: 'Flashcard not found' });
  }

  const { question, answer, category, difficulty, favorite } = req.body;

  db.flashcards[index] = {
    ...db.flashcards[index],
    question: question !== undefined ? question : db.flashcards[index].question,
    answer: answer !== undefined ? answer : db.flashcards[index].answer,
    category: category !== undefined ? category : db.flashcards[index].category,
    difficulty: difficulty !== undefined ? difficulty : db.flashcards[index].difficulty,
    favorite: favorite !== undefined ? (favorite ? 1 : 0) : db.flashcards[index].favorite,
    updatedAt: new Date().toISOString()
  };

  writeDB();
  res.json({ success: true, count: 1, card: db.flashcards[index] });
});

// 8. Delete flashcard
app.delete('/api/flashcards/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const index = db.flashcards.findIndex(c => c.id === id);

  if (index === -1) {
    return res.status(404).json({ error: 'Flashcard not found' });
  }

  db.flashcards.splice(index, 1);
  writeDB();
  res.json({ success: true, count: 1 });
});

// 9. Get study logs
app.get('/api/study-logs', (req, res) => {
  let logs = [...db.study_logs];
  logs.sort((a, b) => b.date.localeCompare(a.date));
  
  const days = parseInt(req.query.days);
  if (!isNaN(days)) {
    logs = logs.slice(0, days);
  }
  
  res.json(logs);
});

// 10. Get today's study count
app.get('/api/study-logs/today', (req, res) => {
  const todayStr = new Date().toISOString().substring(0, 10);
  const log = db.study_logs.find(l => l.date === todayStr);
  res.json({ count: log ? log.cards_count : 0 });
});

// 11. Log study activity
app.post('/api/study-logs/log', (req, res) => {
  const todayStr = new Date().toISOString().substring(0, 10);
  const index = db.study_logs.findIndex(l => l.date === todayStr);

  if (index === -1) {
    db.study_logs.push({ date: todayStr, cards_count: 1 });
  } else {
    db.study_logs[index].cards_count += 1;
  }

  writeDB();
  const log = db.study_logs.find(l => l.date === todayStr);
  res.json({ success: true, count: log.cards_count });
});

// Serve frontend static files
const frontendBuildPath = path.join(__dirname, '../Front-end/build/web');
app.use(express.static(frontendBuildPath));

// Catch-all route to serve index.html for Single Page Application routing (if needed)
app.get('*', (req, res, next) => {
  // If it starts with /api, forward to 404
  if (req.path.startsWith('/api')) {
    return next();
  }
  if (fs.existsSync(path.join(frontendBuildPath, 'index.html'))) {
    res.sendFile(path.join(frontendBuildPath, 'index.html'));
  } else {
    res.send('Server is running. Frontend build is not yet generated. Please build the frontend web project first.');
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on http://localhost:${PORT}`);
});
