/* Copyright (c) 2025 Artiom Gurduz
   SPDX-License-Identifier: LicenseRef-Proprietary
   Ownership remains with the author. Internal use by ART ROCKET is permitted. */
(function(){
  function setProgress(p,label){
    var f=document.getElementById('fill');
    p = Math.max(0, Math.min(100, Number(p)||0));
    if(f){ f.style.width = p + '%'; }
    var pct = document.getElementById('pct');
    if(pct){ pct.innerText = Math.round(p) + '%'; }
    if(label){
      var lbl = document.getElementById('lbl');
      if(lbl){ lbl.innerText = label; }
    }
  }
  // доступно из Ruby
  window.setProgress = setProgress;
})();
