import { fetchNui } from "./fetchNui.js";

const optionsWrapper = document.getElementById("options-wrapper");

function onClick(e) {
  if (e) e.stopPropagation();
  this.style.pointerEvents = "none";

  fetchNui("select", [this.targetType, this.targetId, this.zoneId]);
  setTimeout(() => {
    if (this) this.style.pointerEvents = "auto";
  }, 100);
}

export function createOptions(type, data, id, zoneId, index = 0) {
  if (data.hide) return;

  const option = document.createElement("div");
  const iconClass = data.icon || "fa-solid fa-circle-dot";
  const iconColor = data.iconColor ? `style="color: ${data.iconColor} !important;"` : "";
  const iconElement = `<i class="fa-fw ${iconClass} option-icon" ${iconColor}></i>`;

  option.innerHTML = `${iconElement}<p class="option-label">${data.label}</p>`;
  option.className = "option-container";
  option.style.animationDelay = `${index * 30}ms`;
  option.targetType = type;
  option.targetId = id;
  option.zoneId = zoneId;

  option.addEventListener("click", onClick);
  optionsWrapper.appendChild(option);
}
