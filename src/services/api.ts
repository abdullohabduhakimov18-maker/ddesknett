import { io } from "socket.io-client";

const API_URL = ""; // Relative to the same host

export const socket = io();

export const api = {
  // Auth
  async login(email: string, password: string) {
    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) {
        const text = await res.text();
        let errorMsg = text;
        try {
          const json = JSON.parse(text);
          errorMsg = json.error || text;
        } catch (e) {}
        throw new Error(errorMsg);
      }
      return res.json();
    } catch (err: any) {
      console.error("API Login Error:", err);
      throw err;
    }
  },

  async signup(data: any) {
    try {
      const res = await fetch(`${API_URL}/api/auth/signup`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (!res.ok) {
        const text = await res.text();
        let errorMsg = text;
        try {
          const json = JSON.parse(text);
          errorMsg = json.error || text;
        } catch (e) {}
        throw new Error(errorMsg);
      }
      return res.json();
    } catch (err: any) {
      console.error("API Signup Error:", err);
      throw err;
    }
  },

  // Jobs
  async getJobs() {
    const res = await fetch(`${API_URL}/api/jobs`);
    return res.json();
  },

  async getJob(id: string) {
    const res = await fetch(`${API_URL}/api/jobs/${id}`);
    return res.json();
  },

  async createJob(data: any) {
    const res = await fetch(`${API_URL}/api/jobs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  async updateJob(id: string, data: any) {
    const res = await fetch(`${API_URL}/api/jobs/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  async deleteJob(id: string) {
    await fetch(`${API_URL}/api/jobs/${id}`, { method: "DELETE" });
  },

  // Users
  async getUsers() {
    const res = await fetch(`${API_URL}/api/users`);
    return res.json();
  },

  async getUser(uid: string) {
    const res = await fetch(`${API_URL}/api/users/${uid}`);
    return res.json();
  },

  async updateUser(uid: string, data: any) {
    const res = await fetch(`${API_URL}/api/users/${uid}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  // Messages
  async getMessages(userId1: string, userId2: string) {
    const res = await fetch(`${API_URL}/api/messages?userId1=${userId1}&userId2=${userId2}`);
    return res.json();
  },

  async sendMessage(data: any) {
    const res = await fetch(`${API_URL}/api/messages`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  // Notifications
  async getNotifications(userId: string) {
    const res = await fetch(`${API_URL}/api/notifications/${userId}`);
    return res.json();
  },

  async markNotificationRead(id: string) {
    await fetch(`${API_URL}/api/notifications/${id}/read`, { method: "PUT" });
  },

  // Tickets
  async getTickets() {
    const res = await fetch(`${API_URL}/api/tickets`);
    return res.json();
  },

  async createTicket(data: any) {
    const res = await fetch(`${API_URL}/api/tickets`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  },

  // Email
  async sendEmail(data: any) {
    const res = await fetch(`${API_URL}/api/send-email`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return res.json();
  }
};
