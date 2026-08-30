import { createOptions } from "./createOptions.js";

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
let isMenuOpen = false;

function updateSelection() {
  const options = document.querySelectorAll('.option-container');
  if (!options.length) return;
  options.forEach(opt => opt.classList.remove('selected'));
  if (selectedIndex < 0) selectedIndex = options.length - 1;
  if (selectedIndex >= options.length) selectedIndex = 0;
  if (options[selectedIndex]) {
      options[selectedIndex].classList.add('selected');
  }
}

window.addEventListener('wheel', (e) => {
  if (!isMenuOpen) return;
  if (e.deltaY > 0) {
      selectedIndex++;
  } else {
      selectedIndex--;
  }
  updateSelection();
});

window.addEventListener('mousedown', (e) => {
  if (!isMenuOpen) return;
  if (e.button === 0) {
      const options = document.querySelectorAll('.option-container');
      if (options[selectedIndex]) {
          if (!e.target.closest('.option-container')) {
              options[selectedIndex].click();
          }
      }
  }
});

window.addEventListener("message", (event) => {
  switch (event.data.event) {
    case "visible": {
      optionsWrapper.innerHTML = "";
      const isVisible = !!event.data.state;
      isMenuOpen = isVisible;
      if (!isVisible) {
          selectedIndex = 0;
      }
      body.style.visibility = isVisible ? "visible" : "hidden";
      targetCursor.classList.remove("target-active");

      if (isVisible) {
        updateCursorPosition(window.innerWidth / 2, window.innerHeight / 2);
      }
      break;
    }

    case "leftTarget": {
      optionsWrapper.innerHTML = "";
      targetCursor.classList.remove("target-active");
      break;
    }

    case "setTarget": {
      optionsWrapper.innerHTML = "";
      targetCursor.classList.add("target-active");

      let optionIndex = 0;

      if (event.data.options) {
        for (const type in event.data.options) {
          event.data.options[type].forEach((data, id) => {
            createOptions(type, data, id + 1, null, optionIndex++);
          });
        }
      }

      if (event.data.zones) {
        for (let i = 0; i < event.data.zones.length; i++) {
          event.data.zones[i].forEach((data, id) => {
            createOptions("zones", data, id + 1, i + 1, optionIndex++);
          });
        }
      }

      positionOptionsWrapper();
      selectedIndex = 0;
      updateSelection();
      break;
    }
  }
});
