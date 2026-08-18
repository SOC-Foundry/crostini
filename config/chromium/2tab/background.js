// crostini · CHG-014 — keep two most-recently-used tabs
const MAX = 2;

function cap() {
  chrome.tabs.query({}, (tabs) => {
    if (chrome.runtime.lastError || !tabs || tabs.length <= MAX) {
      return;
    }
    const keep = new Set(
      tabs
        .slice()
        .sort((a, b) => (b.lastAccessed || 0) - (a.lastAccessed || 0))
        .slice(0, MAX)
        .map((t) => t.id)
    );
    for (const t of tabs) {
      if (t.id != null && !keep.has(t.id)) {
        chrome.tabs.remove(t.id);
      }
    }
  });
}

let timer = 0;
function schedule() {
  clearTimeout(timer);
  timer = setTimeout(cap, 40);
}

chrome.tabs.onCreated.addListener(schedule);
chrome.tabs.onAttached.addListener(schedule);
chrome.windows.onCreated.addListener(schedule);
chrome.runtime.onStartup.addListener(schedule);
chrome.runtime.onInstalled.addListener(schedule);
schedule();
