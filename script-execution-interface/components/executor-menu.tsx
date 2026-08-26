'use client'

import { useState } from 'react'

const options = [
  ['Unlock FPS', true],
  ['Auto Launch', false],
  ['Auto Attach', true],
  ['Internal UI', true],
  ['Legacy UI', true],
  ['Top Most', true],
] as const

function CloseIcon() {
  return <span className="close-icon" aria-hidden="true" />
}

function OptionPanel() {
  const [checked, setChecked] = useState<Record<string, boolean>>(
    Object.fromEntries(options.map(([label, value]) => [label, value])),
  )

  return (
    <section className="window option-window" aria-label="Application options">
      <header className="option-titlebar">
        <button type="button" className="window-control close-control" aria-label="Close options">
          <CloseIcon />
        </button>
      </header>
      <div className="option-list">
        {options.map(([label]) => (
          <label className="option-row" key={label}>
            <input
              type="checkbox"
              checked={checked[label]}
              onChange={() => setChecked((current) => ({ ...current, [label]: !current[label] }))}
            />
            <span className="checkmark" aria-hidden="true" />
            <span>{label}</span>
          </label>
        ))}
        <button type="button" className="kill-button">Kill Roblox</button>
      </div>
    </section>
  )
}

function BrandMark() {
  return (
    <span className="brand-mark" aria-hidden="true">
      <i />
      <i />
    </span>
  )
}

function EditorPanel() {
  const [tabs, setTabs] = useState(['New Tab'])
  const [activeTab, setActiveTab] = useState(0)

  function addTab() {
    setTabs((current) => [...current, 'New Tab'])
    setActiveTab(tabs.length)
  }

  function closeTab(index: number) {
    if (tabs.length === 1) return
    setTabs((current) => current.filter((_, tabIndex) => tabIndex !== index))
    setActiveTab((current) => Math.max(0, current > index ? current - 1 : Math.min(current, tabs.length - 2)))
  }

  return (
    <section className="window editor-window" aria-label="Script editor">
      <header className="titlebar">
        <BrandMark />
        <div className="titlebar-controls" aria-hidden="true">
          <span className="minimize" />
          <CloseIcon />
        </div>
      </header>
      <div className="editor-layout">
        <div className="editor-main">
          <nav className="tabbar" aria-label="Editor tabs">
            <span className="output-tab">Output</span>
            {tabs.map((tab, index) => (
              <button
                type="button"
                key={`${tab}-${index}`}
                className={index === activeTab ? 'editor-tab active' : 'editor-tab'}
                onClick={() => setActiveTab(index)}
              >
                {tab}
                <span
                  className="tab-close"
                  role="button"
                  tabIndex={0}
                  aria-label={`Close ${tab}`}
                  onClick={(event) => {
                    event.stopPropagation()
                    closeTab(index)
                  }}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') closeTab(index)
                  }}
                >×</span>
              </button>
            ))}
            <button type="button" className="add-tab" onClick={addTab} aria-label="Add tab">+</button>
          </nav>
          <div className="code-area" role="textbox" aria-label="Code editor" tabIndex={0}>
            <span className="line-number">1</span>
            <span className="code-keyword">print</span><span className="code-bracket">(</span><span className="code-string">&quot;I love life&quot;</span><span className="code-bracket">)</span><span className="caret" />
          </div>
        </div>
        <aside className="file-pane">
          <div className="file-name">BSS.txt</div>
        </aside>
      </div>
      <footer className="editor-footer">
        <div className="footer-group">
          {['Execute', 'Open', 'Save', 'Clear', 'Attach'].map((label) => <button type="button" key={label}>{label}</button>)}
        </div>
        <div className="footer-group footer-right">
          <button type="button">Script Hub</button>
          <button type="button">Settings</button>
        </div>
      </footer>
    </section>
  )
}

function ScriptHubPanel() {
  return (
    <section className="window hub-window" aria-label="Script hub">
      <header className="hub-titlebar">
        <button type="button" className="window-control close-control" aria-label="Close script hub">
          <CloseIcon />
        </button>
      </header>
      <div className="hub-content">
        <aside className="script-list">
          <button type="button">Dark Dex</button>
          <button type="button">Remote Spy</button>
          <button type="button">Script Dumpe</button>
        </aside>
        <div className="hub-right">
          <div className="hub-pane" />
          <div className="hub-pane lower-pane" />
          <button type="button" className="hub-execute">Execute</button>
        </div>
      </div>
    </section>
  )
}

export function ExecutorMenu() {
  return (
    <div className="menu-stage">
      <OptionPanel />
      <EditorPanel />
      <ScriptHubPanel />
    </div>
  )
}
