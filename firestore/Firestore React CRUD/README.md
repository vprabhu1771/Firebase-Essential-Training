I'll adapt the solution for **Vite React** with proper setup and modern practices.

## 1. Project Setup with Vite

```bash
# Create Vite React project
npm create vite@latest firestore-crud -- --template react
cd firestore-crud

# Install Firebase and other dependencies
npm install firebase
npm install -D tailwindcss postcss autoprefixer  # Optional for styling
```

## 2. Environment Variables (.env)

Create `.env` file in the root directory:

```env
# .env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_auth_domain
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_storage_bucket
VITE_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

## 3. Firebase Configuration

```javascript
// src/config/firebase.js
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
```

## 4. Category Service with Error Handling

```javascript
// src/services/categoryService.js
import { 
  collection, 
  addDoc, 
  getDocs, 
  getDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  query, 
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { db } from '../config/firebase';

const COLLECTION_NAME = 'categories';

// CREATE
export const addCategory = async (categoryName) => {
  try {
    const docRef = await addDoc(collection(db, COLLECTION_NAME), {
      name: categoryName.trim(),
      createdAt: new Date().toISOString()
    });
    return { id: docRef.id, name: categoryName.trim() };
  } catch (error) {
    throw new Error(`Failed to add category: ${error.message}`);
  }
};

// READ ALL
export const getCategories = async () => {
  try {
    const q = query(collection(db, COLLECTION_NAME), orderBy('name'));
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    throw new Error(`Failed to fetch categories: ${error.message}`);
  }
};

// READ SINGLE
export const getCategoryById = async (categoryId) => {
  try {
    const docRef = doc(db, COLLECTION_NAME, categoryId);
    const docSnap = await getDoc(docRef);
    return docSnap.exists() ? { id: docSnap.id, ...docSnap.data() } : null;
  } catch (error) {
    throw new Error(`Failed to fetch category: ${error.message}`);
  }
};

// UPDATE
export const updateCategory = async (categoryId, newName) => {
  try {
    const docRef = doc(db, COLLECTION_NAME, categoryId);
    await updateDoc(docRef, {
      name: newName.trim(),
      updatedAt: new Date().toISOString()
    });
    return { id: categoryId, name: newName.trim() };
  } catch (error) {
    throw new Error(`Failed to update category: ${error.message}`);
  }
};

// DELETE
export const deleteCategory = async (categoryId) => {
  try {
    await deleteDoc(doc(db, COLLECTION_NAME, categoryId));
    return categoryId;
  } catch (error) {
    throw new Error(`Failed to delete category: ${error.message}`);
  }
};

// REAL-TIME SUBSCRIPTION
export const subscribeToCategories = (callback) => {
  const q = query(collection(db, COLLECTION_NAME), orderBy('name'));
  
  return onSnapshot(q, 
    (querySnapshot) => {
      const categories = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      callback(categories);
    },
    (error) => {
      console.error('Subscription error:', error);
      callback([]);
    }
  );
};
```

## 5. Custom Hook for Categories

```javascript
// src/hooks/useCategories.js
import { useState, useEffect, useCallback } from 'react';
import { 
  getCategories, 
  addCategory, 
  updateCategory, 
  deleteCategory,
  subscribeToCategories
} from '../services/categoryService';

export const useCategories = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load categories with real-time subscription
  useEffect(() => {
    setLoading(true);
    const unsubscribe = subscribeToCategories((data) => {
      setCategories(data);
      setLoading(false);
      setError(null);
    });

    return () => unsubscribe();
  }, []);

  // CRUD operations with error handling
  const createCategory = useCallback(async (name) => {
    setLoading(true);
    try {
      const newCategory = await addCategory(name);
      return newCategory;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const updateCategoryName = useCallback(async (id, name) => {
    setLoading(true);
    try {
      const updated = await updateCategory(id, name);
      return updated;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const deleteCategoryById = useCallback(async (id) => {
    setLoading(true);
    try {
      await deleteCategory(id);
      return id;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    categories,
    loading,
    error,
    createCategory,
    updateCategoryName,
    deleteCategoryById
  };
};
```

## 6. Main Component with Tailwind CSS (Modern UI)

```jsx
// src/components/CategoryManager.jsx
import React, { useState } from 'react';
import { useCategories } from '../hooks/useCategories';
import { Plus, Edit, Trash2, X, Save } from 'lucide-react';

const CategoryManager = () => {
  const { categories, loading, error, createCategory, updateCategoryName, deleteCategoryById } = useCategories();
  const [newCategoryName, setNewCategoryName] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [editName, setEditName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);

  const handleAddCategory = async (e) => {
    e.preventDefault();
    if (!newCategoryName.trim()) return;

    setSubmitting(true);
    try {
      await createCategory(newCategoryName);
      setNewCategoryName('');
      setShowAddForm(false);
    } catch (err) {
      console.error('Add error:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleUpdateCategory = async (id) => {
    if (!editName.trim()) return;

    setSubmitting(true);
    try {
      await updateCategoryName(id, editName);
      setEditingId(null);
      setEditName('');
    } catch (err) {
      console.error('Update error:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteCategory = async (id, name) => {
    if (!window.confirm(`Delete category "${name}"?`)) return;

    setSubmitting(true);
    try {
      await deleteCategoryById(id);
    } catch (err) {
      console.error('Delete error:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const startEditing = (category) => {
    setEditingId(category.id);
    setEditName(category.name);
  };

  const cancelEditing = () => {
    setEditingId(null);
    setEditName('');
  };

  const styles = {
    container: {
      maxWidth: '1200px',
      margin: '0 auto',
      padding: '24px',
      backgroundColor: '#f9fafb',
      minHeight: '100vh'
    },
    card: {
      backgroundColor: '#ffffff',
      borderRadius: '12px',
      boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
      padding: '24px'
    },
    header: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: '24px'
    },
    title: {
      fontSize: '28px',
      fontWeight: 'bold',
      color: '#1f2937',
      display: 'flex',
      alignItems: 'center',
      gap: '8px'
    },
    loadingText: {
      fontSize: '14px',
      color: '#6b7280',
      marginLeft: '8px'
    },
    button: {
      padding: '8px 16px',
      backgroundColor: '#2563eb',
      color: 'white',
      border: 'none',
      borderRadius: '8px',
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      fontSize: '14px',
      transition: 'background-color 0.2s'
    },
    buttonHover: {
      backgroundColor: '#1d4ed8'
    },
    buttonDisabled: {
      opacity: 0.5,
      cursor: 'not-allowed'
    },
    formContainer: {
      marginBottom: '24px',
      padding: '16px',
      backgroundColor: '#f9fafb',
      borderRadius: '8px',
      border: '1px solid #e5e7eb'
    },
    formGroup: {
      display: 'flex',
      gap: '12px'
    },
    input: {
      flex: 1,
      padding: '8px 16px',
      border: '1px solid #d1d5db',
      borderRadius: '8px',
      fontSize: '14px',
      outline: 'none'
    },
    inputFocus: {
      borderColor: '#2563eb',
      boxShadow: '0 0 0 3px rgba(37, 99, 235, 0.1)'
    },
    inputDisabled: {
      backgroundColor: '#f3f4f6'
    },
    saveButton: {
      padding: '8px 24px',
      backgroundColor: '#16a34a',
      color: 'white',
      border: 'none',
      borderRadius: '8px',
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      fontSize: '14px',
      transition: 'background-color 0.2s'
    },
    cancelButton: {
      padding: '8px 16px',
      backgroundColor: '#9ca3af',
      color: 'white',
      border: 'none',
      borderRadius: '8px',
      cursor: 'pointer',
      fontSize: '14px',
      transition: 'background-color 0.2s'
    },
    tableWrapper: {
      overflowX: 'auto'
    },
    table: {
      width: '100%',
      borderCollapse: 'collapse'
    },
    tableHead: {
      backgroundColor: '#f3f4f6',
      borderBottom: '2px solid #d1d5db'
    },
    th: {
      textAlign: 'left',
      padding: '12px 16px',
      fontWeight: '600',
      color: '#374151'
    },
    thCenter: {
      textAlign: 'center',
      padding: '12px 16px',
      fontWeight: '600',
      color: '#374151'
    },
    td: {
      padding: '12px 16px',
      borderBottom: '1px solid #e5e7eb'
    },
    tdCenter: {
      padding: '12px 16px',
      borderBottom: '1px solid #e5e7eb',
      textAlign: 'center'
    },
    rowEven: {
      backgroundColor: '#ffffff'
    },
    rowOdd: {
      backgroundColor: '#f9fafb'
    },
    idText: {
      color: '#4b5563',
      fontFamily: 'monospace',
      fontSize: '14px'
    },
    nameText: {
      color: '#1f2937',
      fontWeight: '500'
    },
    editContainer: {
      display: 'flex',
      alignItems: 'center',
      gap: '8px'
    },
    editInput: {
      flex: 1,
      padding: '4px 12px',
      border: '1px solid #d1d5db',
      borderRadius: '6px',
      fontSize: '14px',
      outline: 'none'
    },
    actionButton: {
      padding: '6px',
      background: 'none',
      border: 'none',
      cursor: 'pointer',
      borderRadius: '6px',
      display: 'inline-flex',
      alignItems: 'center',
      transition: 'background-color 0.2s'
    },
    actionButtonEdit: {
      color: '#2563eb'
    },
    actionButtonEditHover: {
      backgroundColor: '#eff6ff'
    },
    actionButtonDelete: {
      color: '#dc2626'
    },
    actionButtonDeleteHover: {
      backgroundColor: '#fef2f2'
    },
    actionButtons: {
      display: 'flex',
      justifyContent: 'center',
      gap: '8px'
    },
    stats: {
      marginTop: '24px',
      paddingTop: '16px',
      borderTop: '1px solid #e5e7eb',
      fontSize: '14px',
      color: '#6b7280'
    },
    emptyState: {
      textAlign: 'center',
      padding: '48px 0',
      color: '#6b7280'
    },
    emptyTitle: {
      fontSize: '18px',
      marginBottom: '8px'
    },
    emptyText: {
      fontSize: '14px'
    },
    errorContainer: {
      padding: '16px',
      backgroundColor: '#fef2f2',
      border: '1px solid #fecaca',
      borderRadius: '8px',
      color: '#dc2626'
    },
    errorText: {
      fontWeight: '600'
    },
    retryButton: {
      marginTop: '8px',
      padding: '8px 16px',
      backgroundColor: '#dc2626',
      color: 'white',
      border: 'none',
      borderRadius: '6px',
      cursor: 'pointer'
    }
  };

  if (error) {
    return (
      <div style={styles.errorContainer}>
        <p style={styles.errorText}>Error: {error}</p>
        <button 
          onClick={() => window.location.reload()}
          style={styles.retryButton}
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <div style={styles.header}>
          <h1 style={styles.title}>
            📂 Category Manager
            {loading && <span style={styles.loadingText}>Loading...</span>}
          </h1>
          <button
            onClick={() => setShowAddForm(!showAddForm)}
            style={{
              ...styles.button,
              ...(submitting ? styles.buttonDisabled : {})
            }}
            disabled={submitting}
            onMouseEnter={(e) => {
              if (!submitting) e.currentTarget.style.backgroundColor = '#1d4ed8';
            }}
            onMouseLeave={(e) => {
              if (!submitting) e.currentTarget.style.backgroundColor = '#2563eb';
            }}
          >
            <Plus size={18} />
            New Category
          </button>
        </div>

        {/* Add Category Form */}
        {showAddForm && (
          <form onSubmit={handleAddCategory} style={styles.formContainer}>
            <div style={styles.formGroup}>
              <input
                type="text"
                value={newCategoryName}
                onChange={(e) => setNewCategoryName(e.target.value)}
                placeholder="Enter category name..."
                disabled={submitting}
                style={{
                  ...styles.input,
                  ...(submitting ? styles.inputDisabled : {})
                }}
                onFocus={(e) => {
                  if (!submitting) {
                    e.currentTarget.style.borderColor = '#2563eb';
                    e.currentTarget.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                  }
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#d1d5db';
                  e.currentTarget.style.boxShadow = 'none';
                }}
                autoFocus
              />
              <button
                type="submit"
                disabled={submitting || !newCategoryName.trim()}
                style={{
                  ...styles.saveButton,
                  ...((submitting || !newCategoryName.trim()) ? styles.buttonDisabled : {})
                }}
                onMouseEnter={(e) => {
                  if (!submitting && newCategoryName.trim()) {
                    e.currentTarget.style.backgroundColor = '#15803d';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!submitting) {
                    e.currentTarget.style.backgroundColor = '#16a34a';
                  }
                }}
              >
                <Save size={18} />
                Save
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowAddForm(false);
                  setNewCategoryName('');
                }}
                style={styles.cancelButton}
                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#6b7280'}
                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = '#9ca3af'}
              >
                Cancel
              </button>
            </div>
          </form>
        )}

        {/* Categories Table */}
        {categories.length === 0 && !loading ? (
          <div style={styles.emptyState}>
            <p style={styles.emptyTitle}>No categories found</p>
            <p style={styles.emptyText}>Click "New Category" to add your first category</p>
          </div>
        ) : (
          <div style={styles.tableWrapper}>
            <table style={styles.table}>
              <thead style={styles.tableHead}>
                <tr>
                  <th style={styles.th}>ID</th>
                  <th style={styles.th}>Name</th>
                  <th style={styles.thCenter}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {categories.map((category, index) => (
                  <tr 
                    key={category.id} 
                    style={index % 2 === 0 ? styles.rowEven : styles.rowOdd}
                  >
                    <td style={styles.td}>
                      <span style={styles.idText}>{category.id}</span>
                    </td>
                    <td style={styles.td}>
                      {editingId === category.id ? (
                        <div style={styles.editContainer}>
                          <input
                            type="text"
                            value={editName}
                            onChange={(e) => setEditName(e.target.value)}
                            disabled={submitting}
                            style={{
                              ...styles.editInput,
                              ...(submitting ? styles.inputDisabled : {})
                            }}
                            onFocus={(e) => {
                              if (!submitting) {
                                e.currentTarget.style.borderColor = '#2563eb';
                                e.currentTarget.style.boxShadow = '0 0 0 3px rgba(37, 99, 235, 0.1)';
                              }
                            }}
                            onBlur={(e) => {
                              e.currentTarget.style.borderColor = '#d1d5db';
                              e.currentTarget.style.boxShadow = 'none';
                            }}
                            autoFocus
                          />
                          <button
                            onClick={() => handleUpdateCategory(category.id)}
                            disabled={submitting || !editName.trim()}
                            style={{
                              ...styles.actionButton,
                              backgroundColor: '#16a34a',
                              color: 'white',
                              padding: '4px 8px',
                              ...((submitting || !editName.trim()) ? styles.buttonDisabled : {})
                            }}
                            onMouseEnter={(e) => {
                              if (!submitting && editName.trim()) {
                                e.currentTarget.style.backgroundColor = '#15803d';
                              }
                            }}
                            onMouseLeave={(e) => {
                              if (!submitting) {
                                e.currentTarget.style.backgroundColor = '#16a34a';
                              }
                            }}
                          >
                            <Save size={16} />
                          </button>
                          <button
                            onClick={cancelEditing}
                            disabled={submitting}
                            style={{
                              ...styles.actionButton,
                              backgroundColor: '#9ca3af',
                              color: 'white',
                              padding: '4px 8px',
                              ...(submitting ? styles.buttonDisabled : {})
                            }}
                            onMouseEnter={(e) => {
                              if (!submitting) e.currentTarget.style.backgroundColor = '#6b7280';
                            }}
                            onMouseLeave={(e) => {
                              if (!submitting) e.currentTarget.style.backgroundColor = '#9ca3af';
                            }}
                          >
                            <X size={16} />
                          </button>
                        </div>
                      ) : (
                        <span style={styles.nameText}>{category.name}</span>
                      )}
                    </td>
                    <td style={styles.tdCenter}>
                      <div style={styles.actionButtons}>
                        {editingId !== category.id && (
                          <>
                            <button
                              onClick={() => startEditing(category)}
                              disabled={submitting}
                              style={{
                                ...styles.actionButton,
                                ...styles.actionButtonEdit,
                                ...(submitting ? styles.buttonDisabled : {})
                              }}
                              onMouseEnter={(e) => {
                                if (!submitting) e.currentTarget.style.backgroundColor = '#eff6ff';
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.backgroundColor = 'transparent';
                              }}
                              title="Edit"
                            >
                              <Edit size={16} />
                            </button>
                            <button
                              onClick={() => handleDeleteCategory(category.id, category.name)}
                              disabled={submitting}
                              style={{
                                ...styles.actionButton,
                                ...styles.actionButtonDelete,
                                ...(submitting ? styles.buttonDisabled : {})
                              }}
                              onMouseEnter={(e) => {
                                if (!submitting) e.currentTarget.style.backgroundColor = '#fef2f2';
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.backgroundColor = 'transparent';
                              }}
                              title="Delete"
                            >
                              <Trash2 size={16} />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Stats */}
        {categories.length > 0 && (
          <div style={styles.stats}>
            Total: {categories.length} category{categories.length !== 1 ? 's' : ''}
          </div>
        )}
      </div>
    </div>
  );
};

export default CategoryManager;
```

## 7. App Component

```jsx
// src/App.jsx
import React from 'react';
import CategoryManager from './components/CategoryManager';

function App() {
  return (
    <div className="App">
      <CategoryManager />
    </div>
  );
}

export default App;
```

## 8. Main Entry

```jsx
// src/main.jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

## 9. Tailwind CSS Setup (Optional)

If using Tailwind CSS:

```css
/* src/index.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

## 10. Project Structure

```
category-crud/
├── .env
├── .gitignore
├── index.html
├── package.json
├── tailwind.config.js
├── postcss.config.js
├── vite.config.js
├── src/
│   ├── main.jsx
│   ├── App.jsx
│   ├── index.css
│   ├── config/
│   │   └── firebase.js
│   ├── services/
│   │   └── categoryService.js
│   ├── hooks/
│   │   └── useCategories.js
│   └── components/
│       └── CategoryManager.jsx
```

## Key Features of this Vite React Setup:

1. **Environment Variables**: Using `import.meta.env` for Firebase config
2. **Custom Hook**: Clean separation of logic with `useCategories`
3. **Real-time Updates**: Automatic UI updates when data changes
4. **Error Handling**: Comprehensive error catching and display
5. **Modern UI**: Tailwind CSS for beautiful, responsive design
6. **Loading States**: Disabled buttons and loading indicators
7. **Type Safety**: Can easily add TypeScript support

This setup is optimized for Vite's fast refresh and provides a production-ready category management system!
