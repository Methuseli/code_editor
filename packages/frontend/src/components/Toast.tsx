import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-react';
import { clsx } from 'clsx';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

interface ToastMessage {
  id: string;
  type: ToastType;
  title: string;
  message: string;
  duration?: number;
}

// Global toast manager
class ToastManager {
  private listeners: ((toasts: ToastMessage[]) => void)[] = [];
  private toasts: ToastMessage[] = [];

  subscribe(callback: (toasts: ToastMessage[]) => void) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  private notify() {
    this.listeners.forEach(callback => callback([...this.toasts]));
  }

  show(toast: Omit<ToastMessage, 'id'>) {
    const id = crypto.randomUUID();
    const newToast: ToastMessage = { id, ...toast };
    
    this.toasts.push(newToast);
    this.notify();

    // Auto remove after duration
    const duration = toast.duration || 5000;
    setTimeout(() => {
      this.remove(id);
    }, duration);

    return id;
  }

  remove(id: string) {
    this.toasts = this.toasts.filter(t => t.id !== id);
    this.notify();
  }
}

export const toastManager = new ToastManager();

// Toast helper functions
export const toast = {
  success: (title: string, message: string, duration?: number) =>
    toastManager.show({ type: 'success', title, message, duration }),
  error: (title: string, message: string, duration?: number) =>
    toastManager.show({ type: 'error', title, message, duration }),
  warning: (title: string, message: string, duration?: number) =>
    toastManager.show({ type: 'warning', title, message, duration }),
  info: (title: string, message: string, duration?: number) =>
    toastManager.show({ type: 'info', title, message, duration }),
};

const ToastItem: React.FC<{ toast: ToastMessage; onRemove: (id: string) => void }> = ({
  toast,
  onRemove
}) => {
  const getIcon = () => {
    switch (toast.type) {
      case 'success':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'error':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'warning':
        return <AlertCircle className="w-5 h-5 text-yellow-500" />;
      case 'info':
        return <Info className="w-5 h-5 text-blue-500" />;
    }
  };

  const getBorderColor = () => {
    switch (toast.type) {
      case 'success':
        return 'border-l-green-500';
      case 'error':
        return 'border-l-red-500';
      case 'warning':
        return 'border-l-yellow-500';
      case 'info':
        return 'border-l-blue-500';
    }
  };

  return (
    <div className={clsx(
      'bg-gray-800 border-l-4 rounded-r-lg shadow-lg p-4 mb-2 max-w-sm',
      getBorderColor()
    )}>
      <div className="flex items-start gap-3">
        {getIcon()}
        <div className="flex-1 min-w-0">
          <h4 className="text-sm font-medium text-white">{toast.title}</h4>
          <p className="text-sm text-gray-300 mt-1">{toast.message}</p>
        </div>
        <button
          onClick={() => onRemove(toast.id)}
          className="text-gray-400 hover:text-white transition-colors"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

export const Toast: React.FC = () => {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  useEffect(() => {
    return toastManager.subscribe(setToasts);
  }, []);

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {toasts.map((toast) => (
        <ToastItem
          key={toast.id}
          toast={toast}
          onRemove={toastManager.remove.bind(toastManager)}
        />
      ))}
    </div>
  );
};