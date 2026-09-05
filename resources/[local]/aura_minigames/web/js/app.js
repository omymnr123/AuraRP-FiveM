// ============================================================================
// AURA MINIGAMES: MASTER NUI ROUTER & BRIDGE
// ============================================================================

window.addEventListener('DOMContentLoaded', () => {
    const appEl = document.getElementById('app');
    const mountEl = document.getElementById('minigame-mount');
    let currentGameInstance = null;

    function sendNUIResult(success) {
        if (currentGameInstance) {
            currentGameInstance.destroy();
            currentGameInstance = null;
        }

        appEl.classList.add('hidden');
        mountEl.innerHTML = '';

        fetch(`https://${GetParentResourceName()}/minigameResult`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ success: success })
        }).catch(() => {});
    }

    function sendNUICancel() {
        if (currentGameInstance) {
            currentGameInstance.destroy();
            currentGameInstance = null;
        }

        appEl.classList.add('hidden');
        mountEl.innerHTML = '';

        fetch(`https://${GetParentResourceName()}/closeMinigame`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).catch(() => {});
    }

    window.addEventListener('message', (event) => {
        const item = event.data;
        if (!item) return;

        if (item.action === 'openMinigame') {
            SoundFX.init();
            appEl.classList.remove('hidden');
            mountEl.innerHTML = '';

            if (currentGameInstance) {
                currentGameInstance.destroy();
                currentGameInstance = null;
            }

            const gameType = (item.game || '').toLowerCase();
            const config = item.config || {};
            config.onFinish = (success) => {
                sendNUIResult(success);
            };

            if (gameType === 'lockpick') {
                currentGameInstance = new LockpickGame(mountEl, config);
            } else if (gameType === 'ecubypass' || gameType === 'ecu') {
                currentGameInstance = new ECUBypassGame(mountEl, config);
            } else if (gameType === 'chemicalreactor' || gameType === 'reactor' || gameType === 'meth') {
                currentGameInstance = new ChemicalReactorGame(mountEl, config);
            } else if (gameType === 'ciphermatrix' || gameType === 'cipher') {
                currentGameInstance = new CipherMatrixGame(mountEl, config);
            } else if (gameType === 'weedpackaging' || gameType === 'packaging' || gameType === 'weed' || gameType === 'cogollo') {
                currentGameInstance = new WeedPackagingGame(mountEl, config);
            } else {
                console.warn('Unknown minigame type:', gameType);
                sendNUICancel();
            }
        } else if (item.action === 'closeMinigame') {
            sendNUICancel();
        }
    });

    // Seguridad de escape
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && !appEl.classList.contains('hidden')) {
            sendNUICancel();
        }
    });
});
