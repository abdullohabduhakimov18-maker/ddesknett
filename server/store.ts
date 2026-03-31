const uuidv4 = () => Math.random().toString(36).substring(2) + Date.now().toString(36);

export interface User {
  uid: string;
  email: string;
  password?: string;
  name?: string;
  role: 'admin' | 'client' | 'engineer';
  createdAt: string;
  [key: string]: any;
}

export interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  type: string;
  salary: string;
  description: string;
  requirements: string[];
  status: 'open' | 'closed';
  postedBy: string;
  createdAt: string;
}

export interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  text: string;
  createdAt: string;
}

export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  read: boolean;
  createdAt: string;
}

class Store {
  private users: User[] = [];
  private jobs: Job[] = [];
  private messages: Message[] = [];
  private notifications: Notification[] = [];
  private tickets: any[] = [];

  constructor() {
    // Seed some data
    this.seed();
  }

  private seed() {
    const adminEmail = process.env.ADMIN_EMAIL || 'logistmate@gmail.com';
    const masterPassword = process.env.MASTER_PASSWORD || 'desklink2026';

    this.users.push({
      uid: 'admin-1',
      email: adminEmail,
      password: masterPassword,
      name: 'Admin User',
      role: 'admin',
      createdAt: new Date().toISOString(),
    });

    // Also keep the old one just in case
    if (adminEmail !== 'admin@desknet.com') {
      this.users.push({
        uid: 'admin-2',
        email: 'admin@desknet.com',
        password: 'password123',
        name: 'Legacy Admin',
        role: 'admin',
        createdAt: new Date().toISOString(),
      });
    }

    this.jobs.push({
      id: 'job-1',
      title: 'Senior Frontend Engineer',
      company: 'TechCorp',
      location: 'Remote',
      type: 'Full-time',
      salary: '$120k - $160k',
      description: 'Looking for a React expert.',
      requirements: ['React', 'TypeScript', 'Tailwind'],
      status: 'open',
      postedBy: 'admin-1',
      createdAt: new Date().toISOString(),
    });
  }

  // Users
  getUsers() { return this.users; }
  getUser(uid: string) { return this.users.find(u => u.uid === uid); }
  getUserByEmail(email: string) { return this.users.find(u => u.email === email); }
  addUser(user: User) { this.users.push(user); return user; }
  updateUser(uid: string, data: Partial<User>) {
    const index = this.users.findIndex(u => u.uid === uid);
    if (index !== -1) {
      this.users[index] = { ...this.users[index], ...data };
      return this.users[index];
    }
    return null;
  }

  // Jobs
  getJobs() { return this.jobs; }
  getJob(id: string) { return this.jobs.find(j => j.id === id); }
  addJob(job: Job) { this.jobs.push(job); return job; }
  updateJob(id: string, data: Partial<Job>) {
    const index = this.jobs.findIndex(j => j.id === id);
    if (index !== -1) {
      this.jobs[index] = { ...this.jobs[index], ...data };
      return this.jobs[index];
    }
    return null;
  }
  deleteJob(id: string) {
    this.jobs = this.jobs.filter(j => j.id !== id);
  }

  // Messages
  getMessages(userId1: string, userId2: string) {
    return this.messages.filter(m => 
      (m.senderId === userId1 && m.receiverId === userId2) ||
      (m.senderId === userId2 && m.receiverId === userId1)
    ).sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
  }
  addMessage(message: Message) { this.messages.push(message); return message; }

  // Notifications
  getNotifications(userId: string) {
    return this.notifications.filter(n => n.userId === userId)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }
  addNotification(notification: Notification) { this.notifications.push(notification); return notification; }
  markNotificationRead(id: string) {
    const n = this.notifications.find(n => n.id === id);
    if (n) n.read = true;
  }

  // Tickets
  getTickets() { return this.tickets; }
  addTicket(ticket: any) { this.tickets.push(ticket); return ticket; }
}

export const store = new Store();
