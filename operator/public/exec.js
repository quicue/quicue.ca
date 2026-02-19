/**
 * exec.js — Shared execution module for demo.quicue.ca views.
 *
 * Provides: API calls to the quicue.ca server, execute buttons,
 * inline result rendering, destructive action confirmation, and
 * a settings panel for configuring the server endpoint.
 *
 * Usage: <script src="exec.js"></script> in any demo.quicue.ca HTML view.
 * Then call Exec.createBtn(resource, provider, action, isDestructive)
 * to get a wired-up execute button element.
 */
(function() {
  'use strict';

  // -- Configuration (persisted in localStorage) --
  var STORAGE_KEY = 'ops_exec_config';
  var config = loadConfig();

  function loadConfig() {
    try {
      var stored = localStorage.getItem(STORAGE_KEY);
      if (stored) return JSON.parse(stored);
    } catch(e) { /* ignore */ }
    return { apiBase: 'https://api.quicue.ca', token: '' };
  }

  function saveConfig() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
    } catch(e) { /* ignore */ }
  }

  // -- Inject styles --
  var style = document.createElement('style');
  style.textContent = [
    '.exec-btn {',
    '  width: 26px; height: 26px;',
    '  border: 1px solid var(--border);',
    '  border-radius: 4px;',
    '  background: var(--elevated);',
    '  color: var(--text-sec);',
    '  cursor: pointer;',
    '  display: inline-flex;',
    '  align-items: center;',
    '  justify-content: center;',
    '  font-size: 0.7rem;',
    '  transition: border-color 0.12s, color 0.12s, background 0.12s;',
    '  vertical-align: middle;',
    '  flex-shrink: 0;',
    '}',
    '.exec-btn:hover { border-color: var(--green); color: var(--green); }',
    '.exec-btn.running {',
    '  border-color: var(--accent);',
    '  color: var(--accent);',
    '  pointer-events: none;',
    '  animation: exec-spin 0.8s linear infinite;',
    '}',
    '.exec-btn.success { border-color: var(--green); color: var(--green); background: rgba(63,185,80,0.08); }',
    '.exec-btn.failed { border-color: var(--red); color: var(--red); background: rgba(248,81,73,0.08); }',
    '.exec-btn.mock { border-color: var(--accent); color: var(--accent); background: rgba(88,166,255,0.08); }',
    '.exec-btn.blocked { border-color: var(--warning); color: var(--warning); background: rgba(210,153,34,0.08); }',
    '@keyframes exec-spin {',
    '  from { transform: rotate(0deg); }',
    '  to { transform: rotate(360deg); }',
    '}',
    '',
    '/* Result display */',
    '.exec-result {',
    '  margin-top: 0.35rem;',
    '  padding: 0.5rem 0.65rem;',
    '  border-radius: 4px;',
    '  font-family: var(--font-mono);',
    '  font-size: 0.7rem;',
    '  line-height: 1.5;',
    '  max-height: 200px;',
    '  overflow-y: auto;',
    '  white-space: pre-wrap;',
    '  word-break: break-all;',
    '}',
    '.exec-result.success {',
    '  background: rgba(63,185,80,0.06);',
    '  border: 1px solid rgba(63,185,80,0.2);',
    '  color: var(--text);',
    '}',
    '.exec-result.failed {',
    '  background: rgba(248,81,73,0.06);',
    '  border: 1px solid rgba(248,81,73,0.2);',
    '  color: var(--text);',
    '}',
    '.exec-result.mock {',
    '  background: rgba(88,166,255,0.06);',
    '  border: 1px solid rgba(88,166,255,0.2);',
    '  color: var(--text-sec);',
    '}',
    '.exec-result.blocked {',
    '  background: rgba(210,153,34,0.06);',
    '  border: 1px solid rgba(210,153,34,0.2);',
    '  color: var(--warning);',
    '}',
    '.exec-result .exec-meta {',
    '  display: flex;',
    '  gap: 0.5rem;',
    '  margin-bottom: 0.25rem;',
    '  font-size: 0.65rem;',
    '  color: var(--text-sec);',
    '}',
    '.exec-result .exec-meta .exec-badge {',
    '  padding: 0.05rem 0.35rem;',
    '  border-radius: 8px;',
    '  font-size: 0.6rem;',
    '  font-weight: 700;',
    '}',
    '.exec-badge.mode-live { background: rgba(63,185,80,0.15); color: var(--green); }',
    '.exec-badge.mode-mock { background: rgba(88,166,255,0.15); color: var(--accent); }',
    '.exec-badge.mode-blocked { background: rgba(210,153,34,0.15); color: var(--warning); }',
    '.exec-badge.rc-ok { color: var(--green); }',
    '.exec-badge.rc-fail { color: var(--red); }',
    '',
    '/* Confirmation dialog */',
    '.exec-confirm-overlay {',
    '  position: fixed;',
    '  inset: 0;',
    '  background: rgba(0,0,0,0.6);',
    '  display: flex;',
    '  align-items: center;',
    '  justify-content: center;',
    '  z-index: 9999;',
    '}',
    '.exec-confirm-dialog {',
    '  background: var(--surface);',
    '  border: 1px solid var(--border);',
    '  border-radius: var(--radius);',
    '  padding: 1.5rem;',
    '  max-width: 420px;',
    '  width: 90%;',
    '  box-shadow: 0 8px 24px rgba(0,0,0,0.4);',
    '}',
    '.exec-confirm-dialog h3 {',
    '  color: var(--red);',
    '  font-size: 1rem;',
    '  margin-bottom: 0.5rem;',
    '}',
    '.exec-confirm-dialog p {',
    '  color: var(--text-sec);',
    '  font-size: 0.85rem;',
    '  margin-bottom: 0.25rem;',
    '}',
    '.exec-confirm-dialog .exec-confirm-cmd {',
    '  font-family: var(--font-mono);',
    '  font-size: 0.8rem;',
    '  color: var(--text);',
    '  background: var(--elevated);',
    '  padding: 0.5rem 0.75rem;',
    '  border-radius: 4px;',
    '  margin: 0.75rem 0;',
    '  word-break: break-all;',
    '}',
    '.exec-confirm-actions {',
    '  display: flex;',
    '  gap: 0.5rem;',
    '  justify-content: flex-end;',
    '  margin-top: 1rem;',
    '}',
    '.exec-confirm-actions button {',
    '  padding: 0.4rem 1rem;',
    '  border-radius: 4px;',
    '  font-size: 0.85rem;',
    '  font-family: var(--font-ui);',
    '  cursor: pointer;',
    '  border: 1px solid var(--border);',
    '}',
    '.exec-cancel-btn {',
    '  background: var(--elevated);',
    '  color: var(--text-sec);',
    '}',
    '.exec-cancel-btn:hover { color: var(--text); }',
    '.exec-destroy-btn {',
    '  background: rgba(248,81,73,0.15);',
    '  border-color: var(--red);',
    '  color: var(--red);',
    '}',
    '.exec-destroy-btn:hover { background: rgba(248,81,73,0.25); }',
    '',
    '/* Settings gear */',
    '.exec-settings-btn {',
    '  margin-left: auto;',
    '  padding: 0.3rem 0.65rem;',
    '  border: 1px solid var(--border);',
    '  border-radius: 4px;',
    '  background: var(--elevated);',
    '  color: var(--text-dim);',
    '  font-size: 0.85rem;',
    '  cursor: pointer;',
    '  transition: color 0.12s, border-color 0.12s;',
    '}',
    '.exec-settings-btn:hover { color: var(--text); border-color: var(--text-sec); }',
    '.exec-settings-btn.configured { color: var(--green); border-color: var(--green); }',
    '',
    '/* Settings panel */',
    '.exec-settings-panel {',
    '  position: fixed;',
    '  top: var(--nav-height);',
    '  right: 0;',
    '  width: 340px;',
    '  background: var(--surface);',
    '  border-left: 1px solid var(--border);',
    '  border-bottom: 1px solid var(--border);',
    '  border-radius: 0 0 0 var(--radius);',
    '  padding: 1rem 1.25rem;',
    '  z-index: 500;',
    '  box-shadow: -4px 4px 12px rgba(0,0,0,0.3);',
    '  display: none;',
    '}',
    '.exec-settings-panel.open { display: block; }',
    '.exec-settings-panel h3 {',
    '  font-size: 0.85rem;',
    '  margin-bottom: 0.75rem;',
    '  color: var(--text);',
    '}',
    '.exec-settings-panel label {',
    '  display: block;',
    '  font-size: 0.7rem;',
    '  text-transform: uppercase;',
    '  letter-spacing: 0.05em;',
    '  color: var(--text-sec);',
    '  margin-bottom: 0.25rem;',
    '}',
    '.exec-settings-panel input {',
    '  width: 100%;',
    '  padding: 0.45rem 0.65rem;',
    '  background: var(--elevated);',
    '  border: 1px solid var(--border);',
    '  border-radius: 4px;',
    '  color: var(--text);',
    '  font-family: var(--font-mono);',
    '  font-size: 0.8rem;',
    '  outline: none;',
    '  margin-bottom: 0.75rem;',
    '}',
    '.exec-settings-panel input:focus { border-color: var(--accent); }',
    '.exec-settings-panel input::placeholder { color: var(--text-dim); }',
    '.exec-settings-panel .exec-status {',
    '  font-size: 0.75rem;',
    '  color: var(--text-dim);',
    '  margin-top: 0.25rem;',
    '}',
    '.exec-settings-panel .exec-status.ok { color: var(--green); }',
    '.exec-settings-panel .exec-status.err { color: var(--red); }',
  ].join('\n');
  document.head.appendChild(style);

  // -- Settings UI: inject gear button into nav --
  function initSettingsUI() {
    var nav = document.querySelector('nav');
    if (!nav) return;

    var gearBtn = document.createElement('button');
    gearBtn.className = 'exec-settings-btn' + (config.apiBase ? ' configured' : '');
    gearBtn.title = 'Execution settings';
    gearBtn.textContent = '\u2699 Exec';
    nav.appendChild(gearBtn);

    var panel = document.createElement('div');
    panel.className = 'exec-settings-panel';

    var h3 = document.createElement('h3');
    h3.textContent = 'Execution Settings';
    panel.appendChild(h3);

    var lbl1 = document.createElement('label');
    lbl1.textContent = 'Server URL';
    panel.appendChild(lbl1);

    var inp1 = document.createElement('input');
    inp1.type = 'text';
    inp1.placeholder = 'https://api.quicue.ca (empty = same origin)';
    inp1.value = config.apiBase;
    panel.appendChild(inp1);

    var lbl2 = document.createElement('label');
    lbl2.textContent = 'Bearer Token';
    panel.appendChild(lbl2);

    var inp2 = document.createElement('input');
    inp2.type = 'password';
    inp2.placeholder = 'Optional bearer token';
    inp2.value = config.token;
    panel.appendChild(inp2);

    var statusEl = document.createElement('div');
    statusEl.className = 'exec-status';
    statusEl.textContent = config.apiBase ? 'Configured: ' + config.apiBase : 'No server configured (mock-only)';
    if (config.apiBase) statusEl.classList.add('ok');
    panel.appendChild(statusEl);

    // Test connection button
    var testBtn = document.createElement('button');
    testBtn.style.cssText = 'margin-top:0.5rem;padding:0.3rem 0.75rem;border:1px solid var(--border);border-radius:4px;background:var(--elevated);color:var(--text-sec);font-size:0.8rem;cursor:pointer;font-family:var(--font-ui);';
    testBtn.textContent = 'Test Connection';
    testBtn.addEventListener('click', function() {
      var base = inp1.value.replace(/\/+$/, '');
      var headers = {};
      if (inp2.value) headers['Authorization'] = 'Bearer ' + inp2.value;
      statusEl.textContent = 'Testing...';
      statusEl.className = 'exec-status';
      fetch(base + '/api/v1/health', { headers: headers })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          statusEl.textContent = 'Connected: ' + data.route_count + ' routes loaded';
          statusEl.className = 'exec-status ok';
        })
        .catch(function(err) {
          statusEl.textContent = 'Failed: ' + err.message;
          statusEl.className = 'exec-status err';
        });
    });
    panel.appendChild(testBtn);

    document.body.appendChild(panel);

    // Save on input change
    inp1.addEventListener('input', function() {
      config.apiBase = inp1.value.replace(/\/+$/, '');
      saveConfig();
      gearBtn.classList.toggle('configured', !!config.apiBase);
      statusEl.textContent = config.apiBase ? 'Configured: ' + config.apiBase : 'No server configured (mock-only)';
      statusEl.className = config.apiBase ? 'exec-status ok' : 'exec-status';
    });
    inp2.addEventListener('input', function() {
      config.token = inp2.value;
      saveConfig();
    });

    // Toggle panel
    gearBtn.addEventListener('click', function(e) {
      e.stopPropagation();
      panel.classList.toggle('open');
    });
    document.addEventListener('click', function(e) {
      if (!panel.contains(e.target) && e.target !== gearBtn) {
        panel.classList.remove('open');
      }
    });
  }

  // -- Core: execute a command --
  function execCommand(resource, provider, action, opts) {
    opts = opts || {};
    var base = config.apiBase;
    var url = base + '/api/v1/resources/' +
      encodeURIComponent(resource) + '/' +
      encodeURIComponent(provider) + '/' +
      encodeURIComponent(action);

    var headers = { 'Content-Type': 'application/json' };
    if (config.token) {
      headers['Authorization'] = 'Bearer ' + config.token;
    }
    if (opts.confirmDestructive) {
      headers['X-Confirm-Destructive'] = 'yes';
    }

    return fetch(url, { method: 'POST', headers: headers })
      .then(function(r) {
        return r.json().then(function(data) {
          data._httpStatus = r.status;
          return data;
        });
      });
  }

  // -- Destructive confirmation dialog --
  function confirmDestructive(resource, action, command) {
    return new Promise(function(resolve) {
      var overlay = document.createElement('div');
      overlay.className = 'exec-confirm-overlay';

      var dialog = document.createElement('div');
      dialog.className = 'exec-confirm-dialog';

      var h3 = document.createElement('h3');
      h3.textContent = 'Destructive Action';
      dialog.appendChild(h3);

      var p1 = document.createElement('p');
      p1.textContent = 'This will execute a destructive action on ' + resource + ':';
      dialog.appendChild(p1);

      var cmdBox = document.createElement('div');
      cmdBox.className = 'exec-confirm-cmd';
      cmdBox.textContent = command;
      dialog.appendChild(cmdBox);

      var p2 = document.createElement('p');
      p2.textContent = action + ' — this cannot be undone.';
      dialog.appendChild(p2);

      var actions = document.createElement('div');
      actions.className = 'exec-confirm-actions';

      var cancelBtn = document.createElement('button');
      cancelBtn.className = 'exec-cancel-btn';
      cancelBtn.textContent = 'Cancel';
      cancelBtn.addEventListener('click', function() {
        overlay.remove();
        resolve(false);
      });
      actions.appendChild(cancelBtn);

      var destroyBtn = document.createElement('button');
      destroyBtn.className = 'exec-destroy-btn';
      destroyBtn.textContent = 'Execute';
      destroyBtn.addEventListener('click', function() {
        overlay.remove();
        resolve(true);
      });
      actions.appendChild(destroyBtn);

      dialog.appendChild(actions);
      overlay.appendChild(dialog);
      document.body.appendChild(overlay);

      // Escape to cancel
      function onKey(e) {
        if (e.key === 'Escape') {
          overlay.remove();
          document.removeEventListener('keydown', onKey);
          resolve(false);
        }
      }
      document.addEventListener('keydown', onKey);
    });
  }

  // -- Create an execute button --
  function createBtn(resource, provider, action, opts) {
    opts = opts || {};
    var isDestructive = !!opts.destructive;
    var command = opts.command || '';

    var btn = document.createElement('button');
    btn.className = 'exec-btn';
    btn.title = 'Execute: ' + provider + '/' + action;
    btn.textContent = '\u25B6';

    btn.addEventListener('click', function(e) {
      e.stopPropagation();

      if (!config.apiBase) {
        showNotConfigured(btn);
        return;
      }

      if (btn.classList.contains('running')) return;

      function doExec(confirm) {
        btn.classList.remove('success', 'failed', 'mock', 'blocked');
        btn.classList.add('running');
        btn.textContent = '\u25CB';

        // Remove any previous result sibling
        var prevResult = btn.parentElement &&
          btn.parentElement.querySelector('.exec-result');
        if (prevResult) prevResult.remove();

        execCommand(resource, provider, action, {
          confirmDestructive: confirm
        }).then(function(data) {
          btn.classList.remove('running');

          var mode = data.mode || 'unknown';
          if (mode === 'live' && (data.returncode === 0 || data.returncode === null)) {
            btn.classList.add('success');
            btn.textContent = '\u2713';
          } else if (mode === 'live') {
            btn.classList.add('failed');
            btn.textContent = '\u2717';
          } else if (mode === 'mock') {
            btn.classList.add('mock');
            btn.textContent = '\u25B6';
          } else if (mode === 'blocked') {
            btn.classList.add('blocked');
            btn.textContent = '\u26A0';
          }

          // Show result if there's a result container callback
          if (opts.onResult) {
            opts.onResult(data);
          }

          // Auto-reset after delay
          setTimeout(function() {
            btn.classList.remove('success', 'failed', 'mock', 'blocked');
            btn.textContent = '\u25B6';
          }, 8000);

        }).catch(function(err) {
          btn.classList.remove('running');
          btn.classList.add('failed');
          btn.textContent = '\u2717';
          if (opts.onResult) {
            opts.onResult({
              mode: 'error',
              output: 'Connection failed: ' + err.message,
              returncode: -1
            });
          }
          setTimeout(function() {
            btn.classList.remove('failed');
            btn.textContent = '\u25B6';
          }, 8000);
        });
      }

      if (isDestructive) {
        confirmDestructive(resource, action, command).then(function(confirmed) {
          if (confirmed) doExec(true);
        });
      } else {
        doExec(false);
      }
    });

    return btn;
  }

  // -- Result element builder --
  function createResultEl(data) {
    var el = document.createElement('div');
    var mode = data.mode || 'unknown';
    var rc = data.returncode;

    if (mode === 'live' && (rc === 0 || rc === null)) {
      el.className = 'exec-result success';
    } else if (mode === 'live') {
      el.className = 'exec-result failed';
    } else if (mode === 'mock') {
      el.className = 'exec-result mock';
    } else if (mode === 'blocked') {
      el.className = 'exec-result blocked';
    } else {
      el.className = 'exec-result failed';
    }

    // Meta line
    var meta = document.createElement('div');
    meta.className = 'exec-meta';

    var modeBadge = document.createElement('span');
    modeBadge.className = 'exec-badge mode-' + mode;
    modeBadge.textContent = mode;
    meta.appendChild(modeBadge);

    if (rc !== undefined && rc !== null) {
      var rcBadge = document.createElement('span');
      rcBadge.className = 'exec-badge ' + (rc === 0 ? 'rc-ok' : 'rc-fail');
      rcBadge.textContent = 'rc=' + rc;
      meta.appendChild(rcBadge);
    }

    if (data.duration_ms !== undefined && data.duration_ms !== null) {
      var dur = document.createElement('span');
      dur.textContent = data.duration_ms + 'ms';
      meta.appendChild(dur);
    }

    el.appendChild(meta);

    // Output
    if (data.output) {
      var out = document.createElement('div');
      out.textContent = data.output;
      el.appendChild(out);
    }

    return el;
  }

  // -- "Not configured" flash --
  function showNotConfigured(btn) {
    var origText = btn.textContent;
    btn.textContent = '\u2699';
    btn.style.color = 'var(--warning)';
    btn.style.borderColor = 'var(--warning)';
    btn.title = 'Configure server URL first (gear icon in nav)';
    setTimeout(function() {
      btn.textContent = origText;
      btn.style.color = '';
      btn.style.borderColor = '';
      btn.title = '';
    }, 2000);
  }

  // -- Parse "provider/action" key into parts --
  function parseCommandKey(key) {
    var slash = key.indexOf('/');
    if (slash > 0) {
      return { provider: key.substring(0, slash), action: key.substring(slash + 1) };
    }
    return { provider: 'other', action: key };
  }

  // -- Initialize on DOM ready --
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSettingsUI);
  } else {
    initSettingsUI();
  }

  // -- Public API --
  window.Exec = {
    createBtn: createBtn,
    createResultEl: createResultEl,
    execCommand: execCommand,
    confirmDestructive: confirmDestructive,
    parseCommandKey: parseCommandKey,
    config: config
  };

})();
