import React, { useState, useEffect } from 'react';
import { useEditor } from '../../context/EditorContext';

export function GistsList({ revision = 0 }) {
    const { openFileInEditor } = useEditor();
    const [gists, setGists] = useState([]);

    useEffect(() => {
        let active = true;
        window.hwAPI.listGists().then(list => { if (active) setGists(Array.isArray(list) ? list : []); }).catch(() => {});
        return () => { active = false; };
    }, [revision]);

    const open = async gist => {
        try {
            const file = await window.hwAPI.readGist(gist.path);
            if (typeof file?.content !== 'string') throw new Error('The gist could not be loaded.');
            openFileInEditor(file.name || gist.name, file.content);
        } catch (error) {
            window.HWToast?.error(error.message, '', 'GitHub Gists');
        }
    };

    if (!gists.length) {
        return <div className="node"><div className="node-caption px-1 py-0.5 text-xs opacity-50">No gists yet — press + to add one.</div></div>;
    }
    return gists.map((gist, index) => (
        <div className="node" key={gist.path || index}>
            <div>
                <div
                    className="node-caption group flex items-center py-0.5 pl-1 opacity-70 hover:opacity-100 active:opacity-50 cursor-default"
                    title={gist.path}
                    onClick={() => open(gist)}
                >
                    <iconify-icon icon="ci:github" class="flex items-center justify-center w-4 min-w-[1rem]" />
                    <div className="ml-2 overflow-ellipsis whitespace-nowrap">{gist.name || 'Gist'}</div>
                </div>
            </div>
        </div>
    ));
}
