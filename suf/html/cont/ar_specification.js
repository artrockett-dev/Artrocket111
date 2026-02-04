/* =========================================================
   AR Specification — инкрементальная отрисовка, live-total,
   валюта из Parameters Bridge (__applyFxSettings), PDF export
   ========================================================= */
(function(){
  const pagesRoot = document.getElementById('pages-root');
  const PAGE_TPL  = document.getElementById('page-tpl');

  /* ── helpers ─────────────────────────────────────────── */
  function todayRO(){
    const d=new Date();
    return `${String(d.getDate()).padStart(2,'0')}.${String(d.getMonth()+1).padStart(2,'0')}.${d.getFullYear()}`;
  }
  function fallbackModelName(){
    const t=(document.title||'').split(/[\\\/]/).pop();
    const u=(location.href||'').split(/[\\\/]/).pop();
    return (t||u||'Contract').replace(/\.(skp|html?)$/i,'');
  }
  // Контракт не автозаполняем — только явная установка
  function currentModelName(){ return (document.querySelector('.inp-contract')?.value || ''); }
  function setModelName(name){
    if (typeof name === 'string') {
      document.querySelectorAll('.inp-contract').forEach(el=> el.value = name);
    }
  }
  window.set_model_name = setModelName;

  /* ── печатная «заморозка» ────────────────────────────── */
  let freezeCounter = 0;
  let printing = false;
  const isFrozen = () => printing || (freezeCounter > 0);
  const freeze   = () => { freezeCounter++; };
  const unfreeze = () => { freezeCounter = Math.max(0, freezeCounter-1); };

  /* ── Валюта ──────────────────────────────────────────── */
  let showCurrency = null;
  function symbolFor(curr){
    if (!curr) return 'MDL';
    try{
      if (typeof window.fxSymbol==='function') return window.fxSymbol(curr) || curr;
      if (window.FX_SYMBOL && window.FX_SYMBOL[curr]) return window.FX_SYMBOL[curr];
    }catch(e){}
    return curr;
  }
  function getShowCurrency(){
    if (showCurrency) return showCurrency;
    try{ if (window.fx && window.fx.show) return String(window.fx.show).toUpperCase(); }catch(e){}
    return 'MDL';
  }
  function tapFxBridge(){
    const applyKey = '__applyFxSettings';
    const chainWrap = (fn) => function(){
      try{
        const payload = arguments[0];
        if (payload && payload.show){
          showCurrency = String(payload.show).toUpperCase();
          try{ if (window.fx) window.fx.show = showCurrency; }catch(e){}
          recalcTotal();
        }
      }catch(e){}
      try{ return fn && fn.apply(this, arguments); }catch(e){}
    };

    const old = window[applyKey];
    if (typeof old === 'function'){
      window[applyKey] = chainWrap(old);
    }else{
      Object.defineProperty(window, applyKey, {
        configurable:true,
        set(v){
          Object.defineProperty(window, applyKey, { value: chainWrap(v), writable:true, configurable:true });
          try{
            if(window.fx && window.fx.show){
              showCurrency = String(window.fx.show).toUpperCase();
              recalcTotal();
            }
          }catch(e){}
        }
      });
    }
    try{ if(window.sketchup && window.sketchup.getFxSettings) window.sketchup.getFxSettings(); }catch(e){}
  }

  /* ── Lists/Cost включение ───────────────────────────── */
  function lists_activate_safe(){
    if(typeof window.lists_activate==='function') window.lists_activate();
    window.currSelection=window.currSelection||{ListSection:[]};
    window.currSelection.ListSection.length=0;
    window.currSelection.ListSection.push('Cost');
    if(typeof window.check_listtablinks==='function') window.check_listtablinks();
    else if(window.sketchup && window.sketchup.get_data) window.sketchup.get_data('list@Cost');
    try{ if(window.sketchup && window.sketchup.get_data) window.sketchup.get_data('model_name'); }catch(e){}
  }

  /* ── страница ───────────────────────────────────────── */
  function createPage(){
    const page = PAGE_TPL.content.firstElementChild.cloneNode(true);
    page.querySelector('.back-btn').addEventListener('click', ()=>{
      const base=location.href.replace(/[#?].*$/,"").replace(/[^/]+$/,"");
      location.href=base+"su_furniture.html";
    });
    page.querySelector('.export-btn').addEventListener('click', exportPDF);
    page.querySelector('.nav-prev').addEventListener('click', ()=>shiftView(-1));
    page.querySelector('.nav-next').addEventListener('click', ()=>shiftView(1));
    const dateEl=page.querySelector('.inp-date'); if(dateEl && !dateEl.value) dateEl.value = todayRO();
    return page;
  }

  function updatePager(){
    const pages = [...pagesRoot.querySelectorAll('.page')];
    pages.forEach((p,i)=>{
      p.querySelector('.p-idx').textContent = String(i+1);
      p.querySelector('.p-all').textContent = String(pages.length);
      const head = p.querySelector('.doc-head');
      const ci   = p.querySelector('.client-info');
      const sb   = p.querySelector('.sum-box');
      if(i===0){ head.style.display='grid'; ci.style.display='grid'; sb.style.visibility='visible'; }
      else{ head.style.display='none'; ci.style.display='none'; sb.style.visibility='hidden'; }
    });
  }

  let visibleIndex = 0;
  function shiftView(delta){
    const pages = [...pagesRoot.querySelectorAll('.page')];
    if(pages.length<=1) return;
    visibleIndex = (visibleIndex + delta + pages.length) % pages.length;
    pages.forEach((p,i)=>{ p.style.display = (i===visibleIndex)?'block':'none'; });
  }

  /* ── геометрия таблиц ───────────────────────────────── */
  function elementVisibleHeight(el){
    const cs = getComputedStyle(el);
    return (cs.display === 'none') ? 0 : (el.offsetHeight || 0);
  }

  function tableMaxHeight(page, isFirstPage){
    const pageRect = page.getBoundingClientRect();
    const inner    = page.querySelector('.inner');
    const leftTable= page.querySelector('.col-left');

    const padBottom = parseInt(getComputedStyle(inner).paddingBottom,10) || 0;
    const foot = page.querySelector('.page-foot');
    const footH = elementVisibleHeight(foot); // при печати = 0

    // нижняя граница страницы
    let bottomLimit = page.clientHeight - padBottom - footH;

    if (isFirstPage){
      const ci = page.querySelector('.client-info');
      if (ci){
        if (printing){
          // В печати client-info в потоке: резервируем под него место
          const ciH = (ci.offsetHeight || 0);
          const ciMT = parseFloat(getComputedStyle(ci).marginTop) || 0;
          bottomLimit -= (ciH + ciMT);
        } else {
          // В окне панель absolute: ограничиваем по её верху
          const ciTop = ci.getBoundingClientRect().top - pageRect.top;
          if (Number.isFinite(ciTop) && ciTop > 0){
            bottomLimit = Math.min(bottomLimit, ciTop);
          }
        }
      }
    }

    const SAFETY = printing ? 18 : 14; // печать: чуть больше зазор
    bottomLimit -= SAFETY;

    const topY = leftTable.getBoundingClientRect().top - pageRect.top;
    const available = bottomLimit - topY;

    return Math.max(40, available); // включая thead
  }

  function makeRow(idx,it){
    const tr=document.createElement('tr');
    tr.innerHTML =
      `<td class="col-num">${idx}</td>
       <td class="col-name">${it.name}</td>
       <td class="col-unit">${it.unit||''}</td>
       <td class="col-qty">${String(it.cnt).replace('.',',')}</td>`;
    return tr;
  }

  /* ── инкрементальная постройка ─ */
  const state = {
    pages: [],
    nextIdx: 1,
    accObserver: null,
    listsObserver: null,
    totalLabelObserver: null,
    accSeen: new WeakSet(),
    observersAttached: false
  };

  function ensureFirstPage(){
    if(state.pages.length===0){
      const p = createPage();
      pagesRoot.appendChild(p);
      state.pages = [p];
      updatePager();
      applySavedClientInfo(p);
      const st = p.querySelector('#calc-progress'); if(st) st.textContent = 'Cost calculation in progress...';
    }
  }

  // === ВАЖНО: берём name из 3-й колонки (index 2), а не из 2-й (provider) ===
  function parseAccRow(tr){
    const tds = tr.querySelectorAll('td');
    if(tds.length < 6) return null;                      // №, provider, name, count, unit, price
    if (tr.querySelector('cost_total_label')) return null;

    // название позиции
    const raw = (tds[2].textContent||'').trim();
    const lc  = raw.toLowerCase();
    if(!raw || /^total\b/.test(lc) || lc.replace(/\s+/g,'')==='total') return null;

    // количество
    const qtyText=(tds[3].textContent||'').trim().replace(/[^\d.,-]/g,'');
    const cnt=parseFloat(qtyText.replace(',','.'))||0;

    // единица
    const unit=(tds[4] ? (tds[4].textContent||'').trim() : '');

    // сумма из .elem_cost
    const ec=tds[5].querySelector('.elem_cost');
    const sum=ec?parseFloat((ec.getAttribute('data-disp')||'0')):0;

    return {name:raw, unit, cnt, sum};
  }

  function appendItem(it){
    if (isFrozen()) return;

    let page = state.pages[state.pages.length-1];
    const leftBody  = page.querySelector('.col-left tbody');
    const rightBody = page.querySelector('.col-right tbody');

    const maxH = tableMaxHeight(page, state.pages.length===1);

    // влево
    let tr = makeRow(state.nextIdx, it);
    leftBody.appendChild(tr);
    let curH = page.querySelector('.col-left').tHead.offsetHeight + leftBody.offsetHeight;
    if(curH > maxH){
      leftBody.removeChild(tr);
      // вправо
      tr = makeRow(state.nextIdx, it);
      rightBody.appendChild(tr);
      const curRH = page.querySelector('.col-right').tHead.offsetHeight + rightBody.offsetHeight;
      if(curRH > maxH){
        rightBody.removeChild(tr);
        // новая страница
        page = createPage();
        page.querySelector('.inp-contract').value = state.pages[0].querySelector('.inp-contract').value;
        page.querySelector('.inp-date').value     = state.pages[0].querySelector('.inp-date').value;
        state.pages.push(page);
        pagesRoot.appendChild(page);
        updatePager();
        page.querySelector('.col-left tbody').appendChild(makeRow(state.nextIdx, it));
      }
    }

    state.nextIdx++;
    const st = state.pages[0].querySelector('#calc-progress'); if(st) st.textContent = '';
    state.pages.forEach((p,i)=> p.style.display = (i===visibleIndex)?'block':'none');
  }

  function recalcTotal(){
    if (isFrozen()) return;
    const acc=document.getElementById('acc_table'); if(!acc) return;
    const ecs=[...acc.getElementsByClassName('elem_cost')];
    let total=0; ecs.forEach(ec=> total += +(ec.getAttribute('data-disp')||0));
    const rounded = Math.round(total/10)*10;

    const cur = getShowCurrency();
    if(state.pages[0]){
      const sumBox = state.pages[0].querySelector('.sum-val');
      sumBox.querySelector('.sum-num').textContent =
        rounded.toLocaleString('ro-RO',{maximumFractionDigits:0});
      sumBox.querySelector('.sum-curr').textContent = ' ' + symbolFor(cur);
    }
  }

  function resetSpec(){
    if (isFrozen()) return;
    pagesRoot.innerHTML='';
    state.pages=[]; state.nextIdx=1; state.accSeen = new WeakSet();
    ensureFirstPage();
  }

  /* ── Observers attach/detach ────────────────────────── */
  function detachObservers(){
    try{ state.accObserver?.disconnect(); }catch(e){}
    try{ state.listsObserver?.disconnect(); }catch(e){}
    try{ state.totalLabelObserver?.disconnect(); }catch(e){}
    state.observersAttached = false;
  }
  function attachObservers(){
    if (state.observersAttached) return;
    const acc=document.getElementById('acc_table'); if(!acc) return;

    state.listsObserver = new MutationObserver(()=>{
      if (isFrozen()) return;
      const fresh=document.getElementById('acc_table');
      if(fresh && fresh!==acc){
        resetSpec();
        detachObservers(); attachObservers();
      }
    });
    const listsTable = document.getElementById('lists_table');
    if(listsTable) state.listsObserver.observe(listsTable,{childList:true,subtree:true});

    state.accObserver = new MutationObserver((muts)=>{
      if (isFrozen()) return;
      let changed = false;
      for(const m of muts){
        if(m.type==='childList'){
          m.addedNodes.forEach(node=>{
            if(node.nodeName==='TR' && !state.accSeen.has(node)){
              const it = parseAccRow(node);
              if(it){ appendItem(it); changed = true; }
              state.accSeen.add(node);
            }
          });
          const table = document.getElementById('acc_table');
          if(table && table.rows.length<=1){ resetSpec(); }
        }else if(m.type==='attributes'){
          if(m.target && m.target.classList && m.target.classList.contains('elem_cost')){
            changed = true;
          }
        }
      }
      if(changed) recalcTotal();
    });
    state.accObserver.observe(acc,{ childList:true, subtree:true, attributes:true });

    state.totalLabelObserver = new MutationObserver(()=>{ if(!isFrozen()) recalcTotal(); });
    const totalLbl = acc.querySelector('cost_total_label');
    if(totalLbl){
      state.totalLabelObserver.observe(totalLbl,{childList:true,characterData:true,subtree:true});
    }

    state.observersAttached = true;
  }

  function processExistingRows(){
    const acc=document.getElementById('acc_table'); if(!acc) return;
    const rows=[...acc.querySelectorAll('tr')];
    for(const tr of rows){
      if(state.accSeen.has(tr)) continue;
      const it=parseAccRow(tr);
      if(it){ appendItem(it); }
      state.accSeen.add(tr);
    }
    recalcTotal();
  }

  function processAndObserve(){
    processExistingRows();
    attachObservers();
  }

  /* ── client info ─────────────────────────────────────── */
  function storageKey(){ return 'AR_SPEC_INFO::' + (currentModelName() || 'default'); }
  function readLocalInfo(){ try{ return JSON.parse(localStorage.getItem(storageKey())||'{}'); }catch(e){ return {}; } }
  function writeLocalInfo(obj){ try{ localStorage.setItem(storageKey(), JSON.stringify(obj||{})); }catch(e){} }

  window.__applySpecInfo = function(payload){
    try{
      const data = (typeof payload==='string') ? JSON.parse(payload) : (payload||{});
      writeLocalInfo(data);
      if(state.pages[0]) fillClientInfo(state.pages[0], data);
    }catch(e){}
  };
  function sendInfoToBridge(data){
    try{
      if(window.sketchup && window.sketchup.set_spec_info){ window.sketchup.set_spec_info(JSON.stringify(data)); }
      else if(window.sketchup && window.sketchup.get_data){ window.sketchup.get_data('spec_info_set<=>'+JSON.stringify(data)); }
    }catch(e){}
  }
  function readInfoFromBridge(){ try{ if(window.sketchup && window.sketchup.get_data){ window.sketchup.get_data('spec_info_get'); } }catch(e){} }

  function collectClientInfo(fromPage){
    const q = s=>fromPage.querySelector(s)?.value?.trim()||'';
    return {
      client:q('.inf-client'),
      product:q('.inf-product'),
      addr2:q('.inf-addr2'),
      eld:q('.inf-eld'),
      designer:q('.inf-designer'),
      distance:q('.inf-distance')
    };
  }
  function fillClientInfo(page, data){
    const set=(sel,val)=>{ const el=page.querySelector(sel); if(el) el.value = val||''; };
    set('.inf-client',data.client);
    set('.inf-product',data.product);
    set('.inf-addr2',data.addr2);
    set('.inf-eld',data.eld);
    set('.inf-designer',data.designer);
    set('.inf-distance',data.distance);
  }
  function applySavedClientInfo(firstPage){
    const saved = readLocalInfo(); fillClientInfo(firstPage, saved);
    const inputs = firstPage.querySelectorAll('.client-info .val');
    let t=null;
    inputs.forEach(inp=>{
      inp.addEventListener('input', ()=>{
        if(t) clearTimeout(t);
        t=setTimeout(()=>{ const data = collectClientInfo(firstPage); writeLocalInfo(data); sendInfoToBridge(data); }, 250);
      });
    });
    readInfoFromBridge();
  }

  /* ── Экспорт PDF ────────────────────────────────────── */
  function showAllPages(){
    [...pagesRoot.querySelectorAll('.page')].forEach(p=> p.style.display='block');
    document.body.classList.add('printing');
  }
  function restorePages(){
    const pages=[...pagesRoot.querySelectorAll('.page')];
    pages.forEach((p,i)=> p.style.display = (i===visibleIndex)?'block':'none');
    document.body.classList.remove('printing');
  }

  function exportPDF(){
    printing = true;
    freeze();
    detachObservers();
    showAllPages();
    try{
      window.print();
    } finally{
      restorePages();
      attachObservers();
      unfreeze();
      printing = false;
    }
  }
  window.exportPDF = exportPDF;

  /* Дополнительно: перехват before/after print для браузеров,
     которые открывают превью несколько раз */
  function beginPrint(){ if(!printing){ printing = true; freeze(); detachObservers(); showAllPages(); } }
  function endPrint(){ restorePages(); attachObservers(); unfreeze(); printing = false; }
  if (typeof window.onbeforeprint !== 'undefined'){
    window.onbeforeprint = beginPrint;
    window.onafterprint  = endPrint;
  }
  try{
    const mq = window.matchMedia('print');
    mq.addEventListener ? mq.addEventListener('change', e => e.matches ? beginPrint() : endPrint())
                        : mq.addListener && mq.addListener(e => e.matches ? beginPrint() : endPrint());
  }catch(e){}

  /* ── boot ───────────────────────────────────────────── */
  function boot(){
    try{ if(window.sketchup&&sketchup.resizeWindow) sketchup.resizeWindow(1020,660); }catch(e){}
    ensureFirstPage();
    tapFxBridge();
    lists_activate_safe();

    const wait = setInterval(()=>{
      const acc=document.getElementById('acc_table');
      if(!acc) return;
      clearInterval(wait);
      processAndObserve();
      try{ if(window.fx && window.fx.show){ showCurrency = String(window.fx.show).toUpperCase(); recalcTotal(); } }catch(e){}
    },100);
  }

  document.addEventListener('DOMContentLoaded', boot);
})();
