import { api, socket } from "./services/api";

// Mock Firebase Auth
export const auth = {
  get currentUser() {
    const user = localStorage.getItem('desklink_user');
    return user ? JSON.parse(user) : null;
  }
};

export const db = {}; // Dummy object

// Auth functions
export const onAuthStateChanged = (authInstance: any, callback: (user: any) => void) => {
  // Initial check
  const user = auth.currentUser;
  callback(user);
  
  // Mock listener for local storage changes
  const handleStorage = () => {
    callback(auth.currentUser);
  };
  window.addEventListener('storage', handleStorage);

  return () => window.removeEventListener('storage', handleStorage);
};

export const signOut = async (authInstance: any) => {
  localStorage.removeItem('desklink_user');
  window.dispatchEvent(new Event('storage'));
};

export const signInWithEmailAndPassword = async (authInstance: any, email: string, pass: string) => {
  const { user } = await api.login(email, pass);
  localStorage.setItem('desklink_user', JSON.stringify(user));
  window.dispatchEvent(new Event('storage'));
  return { user };
};

export const createUserWithEmailAndPassword = async (authInstance: any, email: string, pass: string, role: string = 'client', name?: string) => {
  const { user } = await api.signup({ email, password: pass, role, name });
  localStorage.setItem('desklink_user', JSON.stringify(user));
  window.dispatchEvent(new Event('storage'));
  return { user };
};

// Firestore functions
export const serverTimestamp = () => new Date().toISOString();

export const doc = (dbInstance: any, ...pathSegments: string[]) => {
  let collectionName = '';
  let id = '';

  if (typeof dbInstance === 'string') {
    collectionName = dbInstance;
    id = pathSegments[0];
  } else if (dbInstance && typeof dbInstance === 'object' && (dbInstance as any).collection) {
    collectionName = (dbInstance as any).collection;
    id = pathSegments[0];
  } else {
    collectionName = pathSegments[0];
    id = pathSegments[1];
  }

  return { collection: collectionName, id };
};

export const collection = (dbInstance: any, ...pathSegments: string[]) => {
  return { collection: pathSegments.join('/') };
};

export const query = (q: any, ...constraints: any[]) => {
  const collectionName = typeof q === 'string' ? q : q.collection;
  return { collection: collectionName, constraints };
};

export const where = (field: string, op: string, value: any) => {
  return { type: 'where', args: [field, op, value] };
};

export const orderBy = (field: string, direction: string = 'asc') => {
  return { type: 'orderBy', args: [field, direction] };
};

export const limit = (n: number) => {
  return { type: 'limit', args: [n] };
};

export const onSnapshot = (q: any, callback: (snapshot: any) => void, errorCallback?: (err: any) => void) => {
  const collectionName = typeof q === 'string' ? q : q.collection;
  
  const load = async () => {
    try {
      let data: any[] = [];
      if (collectionName === 'jobs' || collectionName === 'job_postings') {
        data = await api.getJobs();
      } else if (collectionName === 'users') {
        data = await api.getUsers();
      } else if (collectionName === 'messages') {
        // This is tricky because it needs query params
        // For now, just return empty or handle specifically if needed
        data = []; 
      } else if (collectionName === 'notifications') {
        const userId = auth.currentUser?.uid;
        if (userId) data = await api.getNotifications(userId);
      } else if (collectionName === 'tickets') {
        data = await api.getTickets();
      }

      callback({
        docs: data.map(item => ({
          id: item.id || item.uid,
          data: () => item,
        })),
        forEach: (cb: any) => {
          data.forEach(item => cb({
            id: item.id || item.uid,
            data: () => item,
          }));
        },
        empty: data.length === 0,
        size: data.length
      });
    } catch (err) {
      if (errorCallback) errorCallback(err);
    }
  };

  load();

  socket.on("data:refetch", (coll) => {
    if (coll === collectionName || (collectionName === 'job_postings' && coll === 'jobs')) {
      load();
    }
  });

  // Fallback polling
  const interval = setInterval(load, 10000);

  return () => {
    clearInterval(interval);
    socket.off("data:refetch");
  };
};

export const addDoc = async (q: any, data: any) => {
  const collectionName = typeof q === 'string' ? q : q.collection;
  if (collectionName === 'jobs' || collectionName === 'job_postings') {
    return api.createJob(data);
  } else if (collectionName === 'messages') {
    return api.sendMessage(data);
  } else if (collectionName === 'tickets') {
    return api.createTicket(data);
  }
  return { id: uuidv4() };
};

export const updateDoc = async (docRef: any, data: any) => {
  const collectionName = docRef.collection;
  if (collectionName === 'jobs' || collectionName === 'job_postings') {
    return api.updateJob(docRef.id, data);
  } else if (collectionName === 'users') {
    return api.updateUser(docRef.id, data);
  } else if (collectionName === 'notifications') {
    return api.markNotificationRead(docRef.id);
  }
};

export const deleteDoc = async (docRef: any) => {
  const collectionName = docRef.collection;
  if (collectionName === 'jobs' || collectionName === 'job_postings') {
    return api.deleteJob(docRef.id);
  }
};

export const setDoc = async (docRef: any, data: any, options?: any) => {
  return updateDoc(docRef, data);
};

export const getDoc = async (docRef: any) => {
  const collectionName = docRef.collection;
  let data = null;
  if (collectionName === 'jobs' || collectionName === 'job_postings') {
    data = await api.getJob(docRef.id);
  } else if (collectionName === 'users') {
    data = await api.getUser(docRef.id);
  }
  return {
    exists: () => !!data,
    data: () => data,
  };
};

export const getDocs = async (q: any) => {
  const collectionName = typeof q === 'string' ? q : q.collection;
  let data: any[] = [];
  if (collectionName === 'jobs' || collectionName === 'job_postings') {
    data = await api.getJobs();
  } else if (collectionName === 'users') {
    data = await api.getUsers();
  }
  return {
    docs: data.map(item => ({
      id: item.id || item.uid,
      data: () => item,
    })),
    forEach: (cb: any) => {
      data.forEach(item => cb({
        id: item.id || item.uid,
        data: () => item,
      }));
    },
    empty: data.length === 0,
    size: data.length
  };
};

export const writeBatch = (dbInstance?: any) => ({
  set: (docRef: any, data: any, options?: any) => setDoc(docRef, data, options),
  update: (docRef: any, data: any) => updateDoc(docRef, data),
  delete: (docRef: any) => deleteDoc(docRef),
  commit: async () => {}
});

export const isFirebaseConfigured = false;

export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

export function handleFirestoreError(error: unknown, operationType: OperationType, path: string | null) {
  console.error('API Error: ', error, operationType, path);
}

const uuidv4 = () => Math.random().toString(36).substring(2) + Date.now().toString(36);
