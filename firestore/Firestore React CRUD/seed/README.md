I'll show you how to seed categories in Firestore with React and Vite. Here are multiple approaches to seed initial category data.

## 1. Category Seeding Service

```javascript
// src/services/seedService.js
import { 
  collection, 
  addDoc, 
  getDocs, 
  deleteDoc, 
  doc, 
  query, 
  where,
  writeBatch
} from 'firebase/firestore';
import { db } from '../config/firebase';

const COLLECTION_NAME = 'categories';

// Sample categories to seed
export const DEFAULT_CATEGORIES = [
  { name: 'Technology' },
  { name: 'Health & Wellness' },
  { name: 'Education' },
  { name: 'Business & Finance' },
  { name: 'Lifestyle' },
  { name: 'Travel' },
  { name: 'Food & Cooking' },
  { name: 'Fashion' },
  { name: 'Sports' },
  { name: 'Entertainment' },
  { name: 'Science' },
  { name: 'Art & Design' },
  { name: 'Music' },
  { name: 'Photography' },
  { name: 'DIY & Crafts' }
];

// SEED - Insert default categories
export const seedCategories = async (categories = DEFAULT_CATEGORIES) => {
  try {
    // Check if categories already exist
    const existingCategories = await getDocs(collection(db, COLLECTION_NAME));
    
    if (!existingCategories.empty) {
      return { 
        success: false, 
        message: 'Categories already exist in the database',
        count: existingCategories.size
      };
    }

    // Add all categories
    const batch = writeBatch(db);
    const timestamp = new Date().toISOString();

    categories.forEach((category) => {
      const docRef = doc(collection(db, COLLECTION_NAME));
      batch.set(docRef, {
        ...category,
        createdAt: timestamp,
        isSeed: true
      });
    });

    await batch.commit();

    return {
      success: true,
      message: `Successfully seeded ${categories.length} categories`,
      count: categories.length
    };
  } catch (error) {
    console.error('Error seeding categories:', error);
    throw new Error(`Failed to seed categories: ${error.message}`);
  }
};

// SEED - Add a single category if it doesn't exist
export const seedSingleCategory = async (categoryName) => {
  try {
    // Check if category already exists
    const q = query(
      collection(db, COLLECTION_NAME), 
      where('name', '==', categoryName)
    );
    const querySnapshot = await getDocs(q);
    
    if (!querySnapshot.empty) {
      return { 
        success: false, 
        message: `Category "${categoryName}" already exists`,
        id: querySnapshot.docs[0].id
      };
    }

    // Add new category
    const docRef = await addDoc(collection(db, COLLECTION_NAME), {
      name: categoryName,
      createdAt: new Date().toISOString(),
      isSeed: true
    });

    return {
      success: true,
      message: `Category "${categoryName}" seeded successfully`,
      id: docRef.id
    };
  } catch (error) {
    console.error('Error seeding category:', error);
    throw new Error(`Failed to seed category: ${error.message}`);
  }
};

// RESET - Delete all categories and re-seed
export const resetAndSeedCategories = async (categories = DEFAULT_CATEGORIES) => {
  try {
    // Delete all existing categories
    const querySnapshot = await getDocs(collection(db, COLLECTION_NAME));
    const batch = writeBatch(db);
    
    querySnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();

    // Seed new categories
    return await seedCategories(categories);
  } catch (error) {
    console.error('Error resetting categories:', error);
    throw new Error(`Failed to reset categories: ${error.message}`);
  }
};

// CHECK - Verify if categories exist
export const checkIfCategoriesExist = async () => {
  try {
    const querySnapshot = await getDocs(collection(db, COLLECTION_NAME));
    return {
      exists: !querySnapshot.empty,
      count: querySnapshot.size
    };
  } catch (error) {
    console.error('Error checking categories:', error);
    throw error;
  }
};

// GET ALL CATEGORY NAMES (for reference)
export const getCategoryNames = async () => {
  try {
    const querySnapshot = await getDocs(collection(db, COLLECTION_NAME));
    return querySnapshot.docs.map(doc => doc.data().name);
  } catch (error) {
    console.error('Error getting category names:', error);
    throw error;
  }
};
```

## 2. Seeding Component with UI

```jsx
// src/components/CategorySeeder.jsx
import React, { useState, useEffect } from 'react';
import { 
  seedCategories, 
  resetAndSeedCategories,
  checkIfCategoriesExist,
  DEFAULT_CATEGORIES,
  seedSingleCategory,
  getCategoryNames
} from '../services/seedService';
import { RefreshCw, Database, Plus, Trash2 } from 'lucide-react';

const CategorySeeder = ({ onSeedComplete }) => {
  const [status, setStatus] = useState({
    loading: false,
    message: '',
    success: false,
    error: false
  });
  const [categoriesExist, setCategoriesExist] = useState(false);
  const [categoryCount, setCategoryCount] = useState(0);
  const [seedStatus, setSeedStatus] = useState('idle'); // idle, seeding, resetting
  const [singleCategoryName, setSingleCategoryName] = useState('');

  // Check if categories exist on mount
  useEffect(() => {
    checkCategories();
  }, []);

  const checkCategories = async () => {
    try {
      const result = await checkIfCategoriesExist();
      setCategoriesExist(result.exists);
      setCategoryCount(result.count);
    } catch (error) {
      console.error('Error checking categories:', error);
    }
  };

  const handleSeed = async () => {
    setStatus({ loading: true, message: 'Seeding categories...', success: false, error: false });
    setSeedStatus('seeding');

    try {
      const result = await seedCategories(DEFAULT_CATEGORIES);
      setStatus({
        loading: false,
        message: result.message,
        success: result.success,
        error: !result.success
      });
      
      await checkCategories();
      if (onSeedComplete && result.success) {
        onSeedComplete();
      }
    } catch (error) {
      setStatus({
        loading: false,
        message: error.message,
        success: false,
        error: true
      });
    } finally {
      setSeedStatus('idle');
    }
  };

  const handleReset = async () => {
    if (!window.confirm('This will delete all existing categories and re-seed with defaults. Continue?')) {
      return;
    }

    setStatus({ loading: true, message: 'Resetting categories...', success: false, error: false });
    setSeedStatus('resetting');

    try {
      const result = await resetAndSeedCategories(DEFAULT_CATEGORIES);
      setStatus({
        loading: false,
        message: result.message,
        success: result.success,
        error: !result.success
      });
      
      await checkCategories();
      if (onSeedComplete && result.success) {
        onSeedComplete();
      }
    } catch (error) {
      setStatus({
        loading: false,
        message: error.message,
        success: false,
        error: true
      });
    } finally {
      setSeedStatus('idle');
    }
  };

  const handleSeedSingle = async (e) => {
    e.preventDefault();
    if (!singleCategoryName.trim()) return;

    setStatus({ loading: true, message: `Adding category "${singleCategoryName}"...`, success: false, error: false });

    try {
      const result = await seedSingleCategory(singleCategoryName.trim());
      setStatus({
        loading: false,
        message: result.message,
        success: result.success,
        error: !result.success
      });
      
      await checkCategories();
      if (onSeedComplete && result.success) {
        onSeedComplete();
      }
      if (result.success) {
        setSingleCategoryName('');
      }
    } catch (error) {
      setStatus({
        loading: false,
        message: error.message,
        success: false,
        error: true
      });
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Database className="text-blue-600" size={24} />
          <h2 className="text-xl font-semibold text-gray-800">Category Seeder</h2>
        </div>
        <div className="text-sm text-gray-500">
          Status: {categoriesExist ? (
            <span className="text-green-600">✅ {categoryCount} categories exist</span>
          ) : (
            <span className="text-yellow-600">⚠️ No categories found</span>
          )}
        </div>
      </div>

      {/* Status Messages */}
      {status.message && (
        <div className={`p-3 rounded-lg mb-4 ${
          status.success ? 'bg-green-50 border border-green-200 text-green-700' :
          status.error ? 'bg-red-50 border border-red-200 text-red-700' :
          'bg-blue-50 border border-blue-200 text-blue-700'
        }`}>
          <p className="text-sm">{status.message}</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Seed Default Categories */}
        <div className="space-y-3">
          <h3 className="font-medium text-gray-700">Seed Default Categories</h3>
          <p className="text-sm text-gray-500">
            Insert {DEFAULT_CATEGORIES.length} default categories into the database
          </p>
          <div className="flex gap-2">
            <button
              onClick={handleSeed}
              disabled={status.loading || categoriesExist}
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 transition-colors"
            >
              <RefreshCw size={18} className={status.loading ? 'animate-spin' : ''} />
              {status.loading && seedStatus === 'seeding' ? 'Seeding...' : 'Seed Categories'}
            </button>
            <button
              onClick={handleReset}
              disabled={status.loading || !categoriesExist}
              className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 transition-colors"
            >
              <Trash2 size={18} />
              Reset
            </button>
          </div>
          {categoriesExist && (
            <p className="text-xs text-yellow-600">
              ⚠️ Categories already exist. Use reset to replace them.
            </p>
          )}
        </div>

        {/* Seed Single Category */}
        <div className="space-y-3 border-t md:border-t-0 md:border-l border-gray-200 pl-0 md:pl-4 pt-4 md:pt-0">
          <h3 className="font-medium text-gray-700">Add Single Category</h3>
          <form onSubmit={handleSeedSingle} className="flex gap-2">
            <input
              type="text"
              value={singleCategoryName}
              onChange={(e) => setSingleCategoryName(e.target.value)}
              placeholder="Enter category name"
              disabled={status.loading}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100"
            />
            <button
              type="submit"
              disabled={status.loading || !singleCategoryName.trim()}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 transition-colors"
            >
              <Plus size={18} />
              Add
            </button>
          </form>
        </div>
      </div>

      {/* Available Categories Preview */}
      <div className="mt-4 pt-4 border-t border-gray-200">
        <details className="text-sm">
          <summary className="cursor-pointer text-gray-600 hover:text-gray-800 font-medium">
            📋 View Default Categories ({DEFAULT_CATEGORIES.length})
          </summary>
          <div className="mt-2 grid grid-cols-3 md:grid-cols-5 gap-1">
            {DEFAULT_CATEGORIES.map((cat, index) => (
              <span key={index} className="text-xs bg-gray-100 px-2 py-1 rounded text-gray-600">
                {cat.name}
              </span>
            ))}
          </div>
        </details>
      </div>
    </div>
  );
};

export default CategorySeeder;
```

## 3. Updated Category Manager with Seeding

```jsx
// src/components/CategoryManager.jsx
import React, { useState } from 'react';
import { useCategories } from '../hooks/useCategories';
import { Plus, Edit, Trash2, X, Save, Database } from 'lucide-react';
import CategorySeeder from './CategorySeeder';

const CategoryManager = () => {
  const { categories, loading, error, createCategory, updateCategoryName, deleteCategoryById } = useCategories();
  const [newCategoryName, setNewCategoryName] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [editName, setEditName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [showSeeder, setShowSeeder] = useState(false);

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

  const handleSeedComplete = () => {
    setShowSeeder(false);
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
      marginBottom: '24px',
      flexWrap: 'wrap',
      gap: '12px'
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
    headerButtons: {
      display: 'flex',
      gap: '8px',
      flexWrap: 'wrap'
    },
    button: {
      padding: '8px 16px',
      border: 'none',
      borderRadius: '8px',
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
      fontSize: '14px',
      fontWeight: '500',
      transition: 'background-color 0.2s'
    },
    buttonPrimary: {
      backgroundColor: '#2563eb',
      color: 'white'
    },
    buttonSeeder: {
      backgroundColor: '#8b5cf6',
      color: 'white'
    },
    buttonSeederActive: {
      backgroundColor: '#7c3aed',
      color: 'white'
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
      gap: '12px',
      flexWrap: 'wrap'
    },
    input: {
      flex: 1,
      padding: '8px 16px',
      border: '1px solid #d1d5db',
      borderRadius: '8px',
      fontSize: '14px',
      outline: 'none',
      minWidth: '200px'
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
      fontWeight: '500',
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
      fontWeight: '500',
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
      gap: '8px',
      flexWrap: 'wrap'
    },
    editInput: {
      flex: 1,
      padding: '4px 12px',
      border: '1px solid #d1d5db',
      borderRadius: '6px',
      fontSize: '14px',
      outline: 'none',
      minWidth: '150px'
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
    actionButtonDelete: {
      color: '#dc2626'
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
          <div style={styles.headerButtons}>
            <button
              onClick={() => setShowSeeder(!showSeeder)}
              style={{
                ...styles.button,
                ...(showSeeder ? styles.buttonSeederActive : styles.buttonSeeder),
                ...(submitting ? styles.buttonDisabled : {})
              }}
              disabled={submitting}
              onMouseEnter={(e) => {
                if (!submitting) {
                  e.currentTarget.style.backgroundColor = showSeeder ? '#6d28d9' : '#7c3aed';
                }
              }}
              onMouseLeave={(e) => {
                if (!submitting) {
                  e.currentTarget.style.backgroundColor = showSeeder ? '#7c3aed' : '#8b5cf6';
                }
              }}
            >
              <Database size={18} />
              {showSeeder ? 'Hide Seeder' : 'Seed Database'}
            </button>
            <button
              onClick={() => setShowAddForm(!showAddForm)}
              style={{
                ...styles.button,
                ...styles.buttonPrimary,
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
        </div>

        {/* Seeder Component */}
        {showSeeder && <CategorySeeder onSeedComplete={handleSeedComplete} />}

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
            <p style={styles.emptyText}>
              {showSeeder ? 'Click "Seed Categories" to add default categories' : 'Click "New Category" to add your first category'}
            </p>
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

## 4. Import Icon for Seeder

```jsx
// src/components/CategoryManager.jsx (add import)
import { Plus, Edit, Trash2, X, Save, Database } from 'lucide-react';
```

## 5. Alternative: Seeding via Script

```javascript
// scripts/seedFirestore.js
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs } from 'firebase/firestore';
import dotenv from 'dotenv';

dotenv.config();

const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY,
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.VITE_FIREBASE_APP_ID
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const DEFAULT_CATEGORIES = [
  'Technology', 'Health & Wellness', 'Education', 
  'Business & Finance', 'Lifestyle', 'Travel', 
  'Food & Cooking', 'Fashion', 'Sports', 'Entertainment'
];

async function seedDatabase() {
  try {
    // Check if categories exist
    const snapshot = await getDocs(collection(db, 'categories'));
    
    if (!snapshot.empty) {
      console.log(`✅ Categories already exist (${snapshot.size} found)`);
      return;
    }

    // Add categories
    const timestamp = new Date().toISOString();
    for (const name of DEFAULT_CATEGORIES) {
      await addDoc(collection(db, 'categories'), {
        name,
        createdAt: timestamp,
        isSeed: true
      });
      console.log(`✅ Added: ${name}`);
    }

    console.log(`🎉 Successfully seeded ${DEFAULT_CATEGORIES.length} categories`);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
  }
}

seedDatabase();
```

Run the script:
```bash
node scripts/seedFirestore.js
```

## 6. Package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "seed": "node scripts/seedFirestore.js"
  }
}
```

## Usage Flow:

1. **First Time Setup**: 
   - Click "Seed Database" button in UI
   - Or run `npm run seed` for command-line seeding

2. **After Seeding**:
   - Categories will appear in the list
   - Each seeded category has "Seeded" badge
   - You can still add, edit, or delete categories

3. **Reset**:
   - Click "Reset" to remove all categories and re-seed defaults

4. **Add Single**:
   - Use "Add Single Category" to add one category at a time
   - Checks for duplicates before adding

This provides a complete seeding solution with both UI and script-based approaches!
