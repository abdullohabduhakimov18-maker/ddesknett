import express from "express";
import { createServer as createViteServer } from "vite";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import nodemailer from "nodemailer";
import { Server } from "socket.io";
import { createServer } from "http";
import { store } from "./server/store";
const uuidv4 = () => Math.random().toString(36).substring(2) + Date.now().toString(36);

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer);

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  if (req.url.startsWith('/api')) {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  }
  next();
});

// --- Auth Routes ---
app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body;
  const user = store.getUserByEmail(email);
  if (!user || user.password !== password) {
    return res.status(401).json({ error: "Invalid email or password" });
  }
  const { password: _, ...userWithoutPassword } = user;
  res.json({ user: userWithoutPassword });
});

app.post("/api/auth/signup", (req, res) => {
  const { email, password, name, role } = req.body;
  if (store.getUserByEmail(email)) {
    return res.status(400).json({ error: "Email already in use" });
  }
  const newUser = store.addUser({
    uid: uuidv4(),
    email,
    password,
    name,
    role: role || 'engineer',
    createdAt: new Date().toISOString(),
  });
  const { password: _, ...userWithoutPassword } = newUser;
  res.json({ user: userWithoutPassword });
});

// --- Job Routes ---
app.get("/api/jobs", (req, res) => {
  res.json(store.getJobs());
});

app.get("/api/jobs/:id", (req, res) => {
  const job = store.getJob(req.params.id);
  if (!job) return res.status(404).json({ error: "Job not found" });
  res.json(job);
});

app.post("/api/jobs", (req, res) => {
  const job = store.addJob({
    ...req.body,
    id: uuidv4(),
    createdAt: new Date().toISOString(),
  });
  io.emit("data:refetch", "jobs");
  res.json(job);
});

app.put("/api/jobs/:id", (req, res) => {
  const job = store.updateJob(req.params.id, req.body);
  if (!job) return res.status(404).json({ error: "Job not found" });
  io.emit("data:refetch", "jobs");
  res.json(job);
});

app.delete("/api/jobs/:id", (req, res) => {
  store.deleteJob(req.params.id);
  io.emit("data:refetch", "jobs");
  res.status(204).send();
});

// --- User Routes ---
app.get("/api/users", (req, res) => {
  res.json(store.getUsers().map(({ password, ...u }) => u));
});

app.get("/api/users/:uid", (req, res) => {
  const user = store.getUser(req.params.uid);
  if (!user) return res.status(404).json({ error: "User not found" });
  const { password, ...userWithoutPassword } = user;
  res.json(userWithoutPassword);
});

app.put("/api/users/:uid", (req, res) => {
  const user = store.updateUser(req.params.uid, req.body);
  if (!user) return res.status(404).json({ error: "User not found" });
  const { password, ...userWithoutPassword } = user;
  res.json(userWithoutPassword);
});

// --- Message Routes ---
app.get("/api/messages", (req, res) => {
  const { userId1, userId2 } = req.query;
  if (!userId1 || !userId2) return res.status(400).json({ error: "Missing user IDs" });
  res.json(store.getMessages(userId1 as string, userId2 as string));
});

app.post("/api/messages", (req, res) => {
  const message = store.addMessage({
    ...req.body,
    id: uuidv4(),
    createdAt: new Date().toISOString(),
  });
  io.emit("message:received", message);
  res.json(message);
});

// --- Notification Routes ---
app.get("/api/notifications/:userId", (req, res) => {
  res.json(store.getNotifications(req.params.userId));
});

app.put("/api/notifications/:id/read", (req, res) => {
  store.markNotificationRead(req.params.id);
  res.status(204).send();
});

// --- Ticket Routes ---
app.get("/api/tickets", (req, res) => {
  res.json(store.getTickets());
});

app.post("/api/tickets", (req, res) => {
  const ticket = store.addTicket({
    ...req.body,
    id: uuidv4(),
    createdAt: new Date().toISOString(),
  });
  res.json(ticket);
});

// Email configuration
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

app.post("/api/send-email", async (req, res) => {
  const { to, subject, text, html } = req.body;

  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.warn("Email credentials not configured. Skipping email send.");
    return res.status(200).json({ success: true, message: "Email skipped (not configured)" });
  }

  try {
    await transporter.sendMail({
      from: `"Desknet Notifications" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text,
      html,
    });
    res.json({ success: true });
  } catch (error) {
    console.error("Error sending email:", error);
    res.status(500).json({ success: false, error: "Failed to send email" });
  }
});

// Socket.io for basic real-time signaling
io.on("connection", (socket) => {
  console.log("A user connected");

  socket.on("disconnect", () => {
    console.log("A user disconnected");
  });

  // Basic signaling for presence and typing (without DB persistence)
  socket.on("presence:update", (data) => {
    socket.broadcast.emit("presence:updated", { [data.uid]: { ...data, lastSeen: new Date().toISOString() } });
  });

  socket.on("typing:update", (data) => {
    socket.broadcast.emit("typing:updated", { [data.id]: data });
  });
  
  socket.on("data:changed", (collection) => {
    socket.broadcast.emit("data:refetch", collection);
  });
});

// For local development
if (process.env.NODE_ENV !== "production") {
  const startDevServer = async () => {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
    
    const PORT = 3000;
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  };
  startDevServer();
} else {
  // Local production test
  app.use(express.static(path.join(__dirname, "dist")));
  app.get("*", (req, res) => {
    res.sendFile(path.resolve(__dirname, "dist/index.html"));
  });
  
  const PORT = 3000;
  httpServer.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

export default app;
