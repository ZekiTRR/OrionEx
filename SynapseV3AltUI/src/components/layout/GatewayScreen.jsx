import React, { useState, useEffect } from 'react';

export function GatewayScreen() {
    const [visible, setVisible] = useState(true);
    const [slidingOut, setSlidingOut] = useState(false);

    const [bgImage] = useState(() => {
        const hour = new Date().getHours();
        if (hour >= 3 && hour < 14) return 'morning.jpg'; // 03:00 AM to 13:59 PM
        if (hour >= 14 && hour < 16) return 'day.jpg'; // 14:00 PM to 15:59 PM
        if (hour >= 16 && hour < 20) return 'evening.jpg'; // 16:00 PM to 19:59 PM
        return 'night.jpg'; // 20:00 PM to 02:59 AM
    });

    useEffect(() => {
        const slideTimer = setTimeout(() => {
            setSlidingOut(true);
        }, 3000);

        const removeTimer = setTimeout(() => {
            setVisible(false);
        }, 4200);

        return () => {
            clearTimeout(slideTimer);
            clearTimeout(removeTimer);
        };
    }, []);

    if (!visible) return null;

    return (
        <div
            id="gateway-page"
            className={`select-none ${slidingOut ? 'sliding-out' : ''}`}
            style={{ backgroundImage: `url('assets/loginbgs/${bgImage}')` }}
        >
            <div id="logo-container">
                <img id="logo" src="assets/logo_white.svg" alt="Synapse X" />
                <div id="extra">
                    <svg class="progress-ring" viewBox="0 0 100 100">
                        <circle class="trail" cx="50" cy="50" r="44" />
                        <circle class="path" cx="50" cy="50" r="44" transform="rotate(-90 50 50)" />
                    </svg>
                    <div id="subtitle" />
                </div>
            </div>
        </div>
    );
}
