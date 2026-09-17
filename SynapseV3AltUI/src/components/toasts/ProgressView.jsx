import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';

function ProgressCard({ header, tasks, onDismiss }) {
    const [isCollapsed, setIsCollapsed] = useState(false);
    const [dismissing, setDismissing] = useState(false);

    const handleDismiss = () => {
        if (dismissing) return;
        setDismissing(true);
        setTimeout(() => {
            onDismiss();
        }, 190);
    };

    useEffect(() => {
        const autoDismissTimes = tasks
            .map(t => {
                if (typeof t.autoDismiss === 'number' && t.autoDismiss > 0) return t.autoDismiss;
                if (t.state === 'complete' || t.state === 'failure') return 3500;
                return null;
            })
            .filter(t => t !== null);

        if (autoDismissTimes.length > 0 && autoDismissTimes.length === tasks.length) {
            const maxDuration = Math.max(...autoDismissTimes);
            const timer = setTimeout(() => {
                handleDismiss();
            }, maxDuration);
            return () => clearTimeout(timer);
        }
    }, [tasks]);

    return (
        <div className={`hw-progress-view rounded-lg border border-white/20 bg-stone-900 shadow-2xl ${dismissing ? 'dismissing' : ''}`}>
            <div className="caption border-b border-white/10 bg-white/5">
                <span>{header}</span>
                <div className="caption-actions">
                    <button
                        className="caption-btn"
                        onClick={() => setIsCollapsed(prev => !prev)}
                        title={isCollapsed ? "Expand" : "Collapse"}
                    >
                        <iconify-icon icon={isCollapsed ? "fluent:chevron-up-16-regular" : "fluent:chevron-down-16-regular"} />
                    </button>
                    <button
                        className="caption-btn"
                        onClick={handleDismiss}
                        title="Dismiss"
                    >
                        <iconify-icon icon="fluent:dismiss-16-regular" />
                    </button>
                </div>
            </div>

            {!isCollapsed && (
                <div className="tasks-list flex flex-col divide-y divide-white/5">
                    {tasks.map(task => (
                        <div key={task.id} className={`task ${task.state || 'in-progress'}`} style={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                            {task.state === 'in-progress' ? (
                                <div className="task-spinner" style={{ marginRight: '0.75rem', marginLeft: 0, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                                    <iconify-icon icon="fluent:spinner-ios-20-regular" class="animate-spin text-blue-400" style={{ fontSize: '1.25rem' }} />
                                </div>
                            ) : task.state === 'failure' ? (
                                <iconify-icon icon={task.icon || "fluent:dismiss-circle-20-filled"} class="text-red-400" style={{ marginRight: '0.75rem', marginLeft: 0, fontSize: '1.25rem', flexShrink: 0 }} />
                            ) : (
                                <iconify-icon icon={task.icon || "fluent:checkmark-20-filled"} class="text-green-400" style={{ marginRight: '0.75rem', marginLeft: 0, fontSize: '1.25rem', flexShrink: 0 }} />
                            )}
                            <div className="flex flex-col min-w-0 flex-1" style={{ display: 'flex', flexDirection: 'column', minWidth: 0, flex: 1 }}>
                                <div className="task-desc font-bold text-sm truncate">{task.desc}</div>
                                {task.subDesc && <div className="subtext text-xs opacity-70 truncate">{task.subDesc}</div>}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

export function ProgressView() {
    const { progressViews } = useApp();

    if (!progressViews || progressViews.size === 0) return null;

    return (
        <div id="canvas-progress" className="canvas-overlay absolute inset-0 z-[150] flex h-full w-full pointer-events-none overflow-hidden" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}>
            <div className="progress-canvas-inner flex h-full w-full select-none items-end justify-end flex-col" style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'flex-end', width: '100%', height: '100%', padding: '1.5rem', gap: '0.85rem', boxSizing: 'border-box' }}>
                {Array.from(progressViews.entries()).map(([header, tasks]) => (
                    <ProgressCard
                        key={header}
                        header={header}
                        tasks={tasks}
                        onDismiss={() => window.HW?.dismissHeader?.(header)}
                    />
                ))}
            </div>
        </div>
    );
}
