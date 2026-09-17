
// Remote interface code.

async function updateEntityOption(option, value) {
    return await fetch(window.location.href + '/' + option, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ value: value })
    });
}

async function main() {
    // Bind to checkboxes.
    document.querySelectorAll('.checkbox').forEach(checkboxElement => {
        checkboxElement.addEventListener('click', () => {
            const schematicName = checkboxElement.getAttribute('data-schema');
            const currentValue = checkboxElement.classList.contains('toggle');
            currentValue ? checkboxElement.classList.remove('toggle') : checkboxElement.classList.add('toggle');
            updateEntityOption(schematicName, !currentValue);
        });
    });

    // Implement pin system, if any.
    const pinForm = document.querySelector('.pin-form');
    if (pinForm != undefined) {
        const submitButton = pinForm.querySelector('button');
        const pinText = pinForm.querySelector('input');
        if (submitButton != undefined && pinText != undefined) {
            submitButton.addEventListener('click', () => {
                document.cookie = `pin=${pinText.value}`;
                location.reload();
            });
        }
    }

    console.log('SXR loaded.');
}

main();