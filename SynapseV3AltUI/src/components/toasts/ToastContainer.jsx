import React, { useEffect, useState } from 'react';
import { useApp } from '../../context/AppContext';

function ToastItem({ toast }) {
    const [progress, setProgress] = useState(100);
    const [dismissing, setDismissing] = useState(false);

    useEffect(() => {
        const duration = toast.duration || 4500;
        const interval = 50;
        const step = (interval / duration) * 100;

        const timer = setInterval(() => {
            setProgress(prev => {
                if (prev <= step) {
                    clearInterval(timer);
                    handleDismiss();
                    return 0;
                }
                return prev - step;
            });
        }, interval);

        return () => clearInterval(timer);
    }, [toast]);

    const handleDismiss = () => {
        setDismissing(true);
        setTimeout(() => {
            toast.onDismiss?.();
        }, 180);
    };

    const getIcon = () => {
        if (toast.icon) return toast.icon;
        switch (toast.type) {
            case 'warning': return 'fluent:warning-20-filled';
            case 'error': return 'fluent:error-circle-20-filled';
            case 'success': return 'fluent:checkmark-circle-20-filled';
            default: return 'fluent:info-20-filled';
        }
    };

    const getIconColor = () => {
        switch (toast.type) {
            case 'warning': return '#fbbf24';
            case 'error': return '#ef4444';
            case 'success': return '#22c55e';
            default: return '#38bdf8';
        }
    };

    return (
        <div className={`hw-toast ${dismissing ? 'dismissing' : ''}`}>
            <div className="hw-toast-header">
                <span>{toast.header || 'Notice'}</span>
                <button className="toast-close" onClick={handleDismiss}>
                    <iconify-icon icon="fluent:dismiss-12-regular" />
                </button>
            </div>
            <div className="hw-toast-body">
                <div className="hw-toast-icon" style={{ color: getIconColor() }}>
                    <iconify-icon icon={getIcon()} />
                </div>
                <div className="hw-toast-text">
                    <div className="hw-toast-desc">{toast.desc}</div>
                    {toast.subDesc && <div className="hw-toast-subdesc">{toast.subDesc}</div>}
                </div>
            </div>
            <div className="hw-toast-progress-bar">
                <div className="hw-toast-progress-fill" style={{ width: `${progress}%` }} />
            </div>
        </div>
    );
}

export function ToastContainer() {
    const { toasts } = useApp();

    if (!toasts || toasts.length === 0) return null;

    return (
        <div id="toast-container">
            {toasts.map(toast => (
                <ToastItem key={toast.id} toast={toast} />
            ))}
        </div>
    );
}
