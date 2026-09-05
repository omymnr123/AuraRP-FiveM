/**
 * ============================================================================
 * AURA RP - MINIMALIST STANDALONE PROGRESS BAR (JS ENGINE)
 * High-Hz Frame Synced Animation - Pure Vanilla JavaScript
 * Zero Audio / Silent Operation - Zero Dependencies - Zero Lag
 * ============================================================================
 */

(function () {
    'use strict';

    // Element references
    const wrapper = document.getElementById('progress-wrapper');
    const actionLabel = document.getElementById('action-label');
    const progressFill = document.getElementById('progress-fill');

    // Execution state
    let isRunning = false;
    let startTime = 0;
    let duration = 0;
    let animationFrameId = null;
    let canCancel = false;

    // ========================================================================
    // NUI POST TO LUA
    // ========================================================================
    function postCallback(endpoint, data = {}) {
        const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'aura_progress';
        fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(() => {});
    }

    // ========================================================================
    // PROGRESS LIFECYCLE
    // ========================================================================
    function startProgress(data) {
        if (isRunning) {
            cancelProgress(false);
        }

        isRunning = true;
        duration = Math.max(100, Number(data.duration) || 3000);
        canCancel = Boolean(data.canCancel);
        startTime = performance.now();

        // UI Setup
        actionLabel.textContent = data.label || 'PROCESANDO...';
        progressFill.style.width = '0%';

        // Reset visual state
        wrapper.classList.remove('cancelled', 'completed');
        wrapper.classList.add('active');

        // Start animation loop
        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
        }
        animationFrameId = requestAnimationFrame(updateProgress);
    }

    function updateProgress(currentTime) {
        if (!isRunning) return;

        const elapsed = currentTime - startTime;
        const progress = Math.min(1, Math.max(0, elapsed / duration));

        // Update fill bar width
        progressFill.style.width = (progress * 100).toFixed(2) + '%';

        if (progress < 1) {
            animationFrameId = requestAnimationFrame(updateProgress);
        } else {
            completeProgress();
        }
    }

    function completeProgress() {
        if (!isRunning) return;
        isRunning = false;

        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
            animationFrameId = null;
        }

        progressFill.style.width = '100%';
        wrapper.classList.add('completed');

        postCallback('progressComplete', { success: true });

        setTimeout(() => {
            wrapper.classList.remove('active', 'completed');
            progressFill.style.width = '0%';
        }, 200);
    }

    function cancelProgress(notifyLua = true) {
        if (!isRunning) return;
        isRunning = false;

        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
            animationFrameId = null;
        }

        wrapper.classList.remove('completed');
        wrapper.classList.add('cancelled');

        if (notifyLua) {
            postCallback('progressCancel', { cancelled: true });
        }

        setTimeout(() => {
            wrapper.classList.remove('active', 'cancelled');
            progressFill.style.width = '0%';
        }, 150);
    }

    // ========================================================================
    // NUI MESSAGE LISTENERS
    // ========================================================================
    window.addEventListener('message', function (event) {
        const item = event.data;
        if (!item || !item.action) return;

        switch (item.action) {
            case 'START_PROGRESS':
                startProgress(item.data || {});
                break;
            case 'CANCEL_PROGRESS':
                cancelProgress(false);
                break;
            default:
                break;
        }
    });

    window.addEventListener('keydown', function (e) {
        if (!isRunning || !canCancel) return;

        if (e.key === 'Escape' || e.key === 'Backspace' || e.keyCode === 27 || e.keyCode === 8) {
            cancelProgress(true);
        }
    });
})();
