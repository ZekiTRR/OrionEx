/**
 * Tactical Control Panel — reference-led reconstruction.
 * Visual rules: fixed 4:3 tactical desktop UI, red active states, zero decorative rounding.
 */
import { Crosshair, MonitorCog, Palette, Settings, Smartphone, TerminalSquare, Wrench } from "lucide-react";
import { useState } from "react";

type RangeControlProps = {
  label: string;
  initial: number;
  valueLabel: string;
  className?: string;
};

function Checkline({ label, initial = false, muted = false }: { label: string; initial?: boolean; muted?: boolean }) {
  const [checked, setChecked] = useState(initial);

  return (
    <label className={`checkline${muted ? " is-muted" : ""}`}>
      <input type="checkbox" checked={checked} onChange={(event) => setChecked(event.target.checked)} />
      <span className="check-box" aria-hidden="true" />
      <span>{label}</span>
    </label>
  );
}

function RangeControl({ label, initial, valueLabel, className = "" }: RangeControlProps) {
  const [value, setValue] = useState(initial);

  return (
    <label className={`range-control ${className}`}>
      <span className="range-label">{label}</span>
      <input
        aria-label={label}
        type="range"
        min="0"
        max="100"
        value={value}
        onChange={(event) => setValue(Number(event.target.value))}
        style={{ background: `linear-gradient(to right, #9b1120 0%, #9b1120 ${value}%, #f7f7f7 ${value}%, #f7f7f7 100%)` }}
      />
      <span className="range-value">{valueLabel}</span>
    </label>
  );
}

function TextField({ label, value, narrow = false }: { label: string; value: string; narrow?: boolean }) {
  return (
    <label className={`field-row${narrow ? " field-row-narrow" : ""}`}>
      <span>{label}</span>
      <input aria-label={label} defaultValue={value} />
    </label>
  );
}

function WeaponGlyph({ kind }: { kind: string }) {
  return <span aria-hidden="true" className={`weapon-glyph weapon-${kind}`} />;
}

export default function Home() {
  const [primaryTab, setPrimaryTab] = useState("RAGE");
  const [weaponTab, setWeaponTab] = useState("RIFLE");

  const primaryTabs = [
    { name: "LEGIT", icon: <Crosshair /> },
    { name: "RAGE", icon: null },
    { name: "VISUALS", icon: <Smartphone /> },
    { name: "MISC", icon: <Wrench /> },
    { name: "SKINS", icon: <Palette /> },
    { name: "SETTINGS", icon: <Settings /> },
    { name: "CONSOLE", icon: <TerminalSquare /> },
  ];

  const weapons = ["pistol", "heavy-pistol", "smg", "RIFLE", "shotgun", "rifle", "sniper", "smg-wide"];

  return (
    <main className="app-shell">
      <section className="aimware-window" aria-label="Aimware weapon configuration menu">
        <header className="main-header">
          <div className="brand-area">
            <img className="brand-mark" src="/manus-storage/aimware-mark_5e31b138.png" alt="" />
            <div className="brand-wordmark">aimware<span>.</span></div>
            <div className="brand-tagline">ONE STEP AHEAD OF THE GAME</div>
          </div>

          <nav className="primary-tabs" aria-label="Main categories">
            {primaryTabs.map((tab) => {
              const isActive = primaryTab === tab.name;
              return (
                <button
                  key={tab.name}
                  className={`primary-tab${isActive ? " is-active" : ""}`}
                  onClick={() => setPrimaryTab(tab.name)}
                  aria-pressed={isActive}
                  aria-label={tab.name}
                >
                  {isActive ? <span className="tab-word">{tab.name}</span> : <span className="primary-icon">{tab.icon}</span>}
                </button>
              );
            })}
          </nav>
        </header>

        <nav className="mode-tabs" aria-label="Configuration mode">
          <button>MAIN</button>
          <button className="is-active">WEAPON</button>
        </nav>

        <nav className="weapon-tabs" aria-label="Weapon category">
          {weapons.map((weapon) => {
            const isActive = weapon === weaponTab;
            if (weapon === "RIFLE") {
              return (
                <button key={weapon} className={`weapon-tab weapon-title${isActive ? " is-active" : ""}`} onClick={() => setWeaponTab(weapon)}>
                  RIFLE
                </button>
              );
            }
            return (
              <button key={weapon} className="weapon-tab" onClick={() => setWeaponTab(weapon)} aria-label={weapon}>
                {weapon === "pistol" ? (
                  <img src="/manus-storage/weapon-silhouette-pistol_bdab3faa.png" alt="" className="asset-glyph pistol-asset" />
                ) : weapon === "rifle" ? (
                  <img src="/manus-storage/weapon-silhouette-rifle_92c4f4ac.png" alt="" className="asset-glyph rifle-asset" />
                ) : (
                  <WeaponGlyph kind={weapon} />
                )}
              </button>
            );
          })}
        </nav>

        <section className="settings-area">
          <Checkline label="Shared Weapon Configuration" />

          <div className="settings-columns">
            <section className="settings-panel" aria-labelledby="accuracy-title">
              <h2 id="accuracy-title">Accuracy</h2>
              <Checkline label="Auto Wall" />
              <TextField label="Auto Stop" value="Minimal Speed" />
              <Checkline label="Auto Stop Crouch" />
              <TextField label="Auto Stop Key" value="" narrow />
              <RangeControl label="Hit Chance" initial={50} valueLabel="50%" />
              <RangeControl label="Min Damage" initial={0} valueLabel="0" />
            </section>

            <section className="settings-panel target-panel" aria-labelledby="target-title">
              <h2 id="target-title">Target</h2>
              <TextField label="Target Selection" value="FOV" />
              <TextField label="Hitbox Priority" value="Head" />
              <TextField label="Bodyaim Hitbox" value="Pelvis" />
              <Checkline label="Adaptive Hitboxes" />
              <RangeControl label="Bodyaim After X Shots" initial={0} valueLabel="0" />
              <RangeControl label="Bodyaim If HP Lower Than" initial={0} valueLabel="0" />
              <Checkline label="Bodyaim If Lethal" />
              <Checkline label="Headaim If Walking" />
              <Checkline label="Ignore Limbs If Walking" />
            </section>

            <section className="settings-panel hitscan-panel" aria-labelledby="hitscan-title">
              <h2 id="hitscan-title">Hitscan</h2>
              <Checkline label="Auto Scale" initial />
              <RangeControl label="Auto Scale Max" initial={100} valueLabel="100%" />
              <Checkline label="Head" initial />
              <RangeControl label="Head Scale" initial={90} valueLabel="90%" />
              <Checkline label="Neck" />
              <RangeControl label="Neck Scale" initial={0} valueLabel="0%" />
              <Checkline label="Chest" />
              <RangeControl label="Chest Scale" initial={0} valueLabel="0%" />
              <Checkline label="Stomach" />
              <RangeControl label="Stomach Scale" initial={0} valueLabel="0%" />
              <Checkline label="Pelvis" muted />
            </section>
          </div>
        </section>

        <footer className="status-footer">
          <span>V4 for Counter-Strike: Global Offensive</span>
          <span>https://aimware.net</span>
        </footer>
      </section>
    </main>
  );
}
