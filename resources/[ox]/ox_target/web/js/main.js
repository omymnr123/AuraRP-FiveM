import { createOptions } from "./createOptions.js";
import { fetchNui } from "./fetchNui.js";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;
const targetCursor = document.getElementById("target-cursor");

let mouseX = window.innerWidth / 2;
let mouseY = window.innerHeight / 2;

function updateCursorPosition(x, y) {
  mouseX = x;
  mouseY = y;
  targetCursor.style.transform = `translate3d(${x}px, ${y}px, 0)`;
}

window.addEventListener("mousemove", (event) => {
  updateCursorPosition(event.clientX, event.clientY);
});

function positionOptionsWrapper() {
  const menuWidth = 240;
  const menuHeight = optionsWrapper.offsetHeight || 120;

  let posX = mouseX + 24;
  let posY = mouseY - 14;

  if (posX + menuWidth > window.innerWidth - 15) {
    posX = Math.max(15, mouseX - menuWidth - 24);
  }
  if (posY + menuHeight > window.innerHeight - 15) {
    posY = Math.max(15, window.innerHeight - menuHeight - 15);
  }
  if (posY < 15) posY = 15;

  optionsWrapper.style.transform = `translate3d(${posX}px, ${posY}px, 0)`;
}

let selectedIndex = 0;
let isTargetingActive = false;
let hasActiveTarget = false;
let isMenuOpen = false;
let currentTargetData = null;

function updateSelection() {
  const options = document.querySelectorAll(".option-container");
  if (!options.length) return;
  options.forEach((opt) => opt.classList.remove("selected"));
  if (selectedIndex < 0) selectedIndex = options.length - 1;
  if (selectedIndex >= options.length) selectedIndex = 0;
  if (options[selectedIndex]) {
    options[selectedIndex].classList.add("selected");
  }
}

function renderOptionsMenu() {
  optionsWrapper.innerHTML = "";
  if (!currentTargetData) return;

  let optionIndex = 0;

  if (currentTargetData.options) {
    for (const type in currentTargetData.options) {
      currentTargetData.options[type].forEach((data, id) => {
        createOptions(type, data, id + 1, null, optionIndex++);
      });
    }
  }

  if (currentTargetData.zones) {
    for (let i = 0; i < currentTargetData.zones.length; i++) {
      currentTargetData.zones[i].forEach((data, id) => {
        createOptions("zones", data, id + 1, i + 1, optionIndex++);
      });
    }
  }

  positionOptionsWrapper();
  selectedIndex = 0;
  updateSelection();
  isMenuOpen = true;
  fetchNui("setMenuOpen", true).catch(() => {});
}

function closeOptionsMenu() {
  isMenuOpen = false;
  optionsWrapper.innerHTML = "";
  selectedIndex = 0;
  fetchNui("setMenuOpen", false).catch(() => {});
}

window.addEventListener("wheel", (e) => {
  if (!isMenuOpen) return;
  if (e.deltaY > 0) {
    selectedIndex++;
  } else {
    selectedIndex--;
  }
  updateSelection();
});

window.addEventListener("mousedown", (e) => {
  if (!isTargetingActive) return;

  if (e.button === 0) {
    // Left Click
    if (e.target.closest(".option-container")) {
      // Direct click on an option
      return;
    }

    if (!isMenuOpen && hasActiveTarget) {
      // Left click on the target: open tooltip menu
      e.preventDefault();
      renderOptionsMenu();
    } else if (isMenuOpen) {
      // Clicked outside option containers while menu was open: close menu
      closeOptionsMenu();
    }
  } else if (e.button === 2) {
    // Right Click
    if (isMenuOpen) {
      closeOptionsMenu();
    }
  }
});

window.addEventListener("message", (event) => {
  switch (event.data.event) {
    case "visible": {
      isTargetingActive = !!event.data.state;
      body.style.visibility = isTargetingActive ? "visible" : "hidden";
      closeOptionsMenu();
      targetCursor.classList.remove("target-active");
      hasActiveTarget = false;
      currentTargetData = null;

      if (isTargetingActive) {
        updateCursorPosition(window.innerWidth / 2, window.innerHeight / 2);
      }
      break;
    }

    case "leftTarget": {
      if (!isMenuOpen) {
        targetCursor.classList.remove("target-active");
        hasActiveTarget = false;
        currentTargetData = null;
        optionsWrapper.innerHTML = "";
      }
      break;
    }

    case "setTarget": {
      currentTargetData = {
        options: event.data.options,
        zones: event.data.zones,
      };
      hasActiveTarget = true;
      targetCursor.classList.add("target-active");

      // If menu was already open (e.g., in a submenu), refresh options immediately
      if (isMenuOpen) {
        renderOptionsMenu();
      }
      break;
    }
  }
});
