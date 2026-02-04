/* Copyright (c) 2025 Artiom Gurduz
   SPDX-License-Identifier: LicenseRef-Proprietary
   Ownership remains with the author. Internal use by ART ROCKET is permitted. */
const Components = {
  currentPath: "",
  hoverTimeout: null,

  openFolder(folderPath) {
    if (!folderPath || !folderPath.trim()) return;
    this.currentPath = folderPath;
    window.currentPath = folderPath;
    document.getElementById("loading").style.display = "block";
    window.sketchup.get_folder_contents(folderPath);
  },

  addComponentToSketchUp(componentPath) {
    if (window.sketchup && componentPath) window.sketchup.load_component(componentPath);
  },

  replaceSelectedComponent(componentPath) {
    if (window.sketchup && componentPath) window.sketchup.replace_component(componentPath);
  },

  addHoverEffect(img) {
    img.addEventListener("mouseenter", () => {
      this.hoverTimeout = setTimeout(() => img.classList.add("expanded"), 1500);
    });
    img.addEventListener("mouseleave", () => {
      clearTimeout(this.hoverTimeout);
      img.classList.remove("expanded");
    });
  },

  populateFolderContents(contents, nameTranslator) {
    const grid = document.getElementById("content");
    const loading = document.getElementById("loading");
    loading.style.display = "none";
    grid.innerHTML = "";

    if ((!contents.folders || contents.folders.length === 0) &&
        (!contents.components || contents.components.length === 0)) {
      grid.innerHTML = `<p style='font-size:16px;color:#666;'>${(window.t && window.t('no.results','No results.')) || 'No results.'}</p>`;
      return;
    }

    (contents.folders || []).forEach(folder => {
      const card = document.createElement("div");
      card.className = "folder-card";
      card.onclick = () => this.openFolder(folder.path);

      const img = document.createElement("img");
      img.src = folder.icon; img.alt = folder.name; card.appendChild(img);

      const name = document.createElement("div");
      name.className = "folder-name";
      name.textContent = nameTranslator ? nameTranslator(folder.name) : folder.name;
      card.appendChild(name);

      grid.appendChild(card);
    });

    (contents.components || []).forEach(cmp => {
      const card = document.createElement("div");
      card.className = "component-card";
      card.onclick = () => this.addComponentToSketchUp(cmp.skp);
      card.oncontextmenu = (e) => { e.preventDefault(); this.replaceSelectedComponent(cmp.skp); };

      const img = document.createElement("img");
      img.src = cmp.png; img.alt = cmp.name; this.addHoverEffect(img); card.appendChild(img);

      const name = document.createElement("div");
      name.className = "component-name";
      name.textContent = nameTranslator ? nameTranslator(cmp.name) : cmp.name;
      card.appendChild(name);

      grid.appendChild(card);
    });
  }
};
