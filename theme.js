(() => {
 const key='carss-theme';
 const button=document.querySelector('#theme-toggle');
 let saved;
 try {saved=localStorage.getItem(key);} catch {}
 let dark=saved==='dark'||(saved!=='light'&&window.matchMedia('(prefers-color-scheme: dark)').matches);
 function apply(){document.documentElement.dataset.theme=dark?'dark':'light';button.textContent=dark?'Light mode':'Dark mode';button.setAttribute('aria-pressed',String(dark));}
 apply();
 button.addEventListener('click',()=>{dark=!dark;apply();try{localStorage.setItem(key,dark?'dark':'light');}catch{}});
})();
