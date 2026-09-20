// Small DOM fixture for game integration tests. It parses markup and selectors;
// rendering, layout, pointer capture, and GPU services remain browser QA concerns.
export class Element extends EventTarget {
  children = []; style = { setProperty(name, value) { this[name] = String(value); }, removeProperty(name) { const old = this[name] ?? ''; delete this[name]; return old; } }; dataset = {}; hidden = false; disabled = false;
  _textContent = ''; tagName = 'DIV'; className = ''; parentElement = null;
  get textContent() { return this._textContent + this.children.map(node => node.textContent).join(''); }
  set textContent(value) { this._textContent = String(value); for (const node of this.children) node.parentElement = null; this.children = []; }
  attributes = new Map();
  classList = {
    add: (...names) => { this.className = [...new Set([...this.className.split(/\s+/).filter(Boolean), ...names])].join(' '); },
    remove: (...names) => { this.className = this.className.split(/\s+/).filter(name => !names.includes(name)).join(' '); },
    toggle: (name, force) => { const has = this.className.split(/\s+/).includes(name); const add = force ?? !has; this.classList[add ? 'add' : 'remove'](name); return add; },
    contains: name => this.className.split(/\s+/).includes(name),
  };
  append(...nodes) { for (const node of nodes) { node.parentElement = this; this.children.push(node); } }
  replaceChildren(...nodes) { for (const node of this.children) node.parentElement = null; this.children = []; this.append(...nodes); }
  cloneNode(deep = false) {
    const clone = new Element();
    for (const key of ['_textContent', 'tagName', 'className', 'hidden', 'disabled']) clone[key] = this[key];
    clone.attributes = new Map(this.attributes); Object.assign(clone.style, this.style); Object.assign(clone.dataset, this.dataset);
    if (deep) clone.append(...this.children.map(node => node.cloneNode(true)));
    return clone;
  }
  setAttribute(name, value) {
    this.attributes.set(name, String(value));
    if (name === 'class') this.className = value;
    if (name.startsWith('data-')) this.dataset[name.slice(5).replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = String(value);
  }
  getAttribute(name) { return this.attributes.get(name) ?? null; }
  removeAttribute(name) { this.attributes.delete(name); if (name.startsWith('data-')) delete this.dataset[name.slice(5).replace(/-([a-z])/g, (_, c) => c.toUpperCase())]; }
  get lastElementChild() { return this.children.at(-1) ?? null; }
  set innerHTML(markup) {
    this.children = []; this._textContent = ''; const stack = [this];
    for (const token of markup.matchAll(/<([^>]+)>|([^<]+)/g)) {
      if (token[2]) { stack.at(-1)._textContent += token[2]; continue; }
      const tag = token[1];
      if (tag.startsWith('/')) { if (stack.length > 1) stack.pop(); continue; }
      const node = new Element(); node.tagName = tag.match(/^[^\s/]+/)[0].toUpperCase();
      for (const attr of tag.matchAll(/([\w-]+)="([^"]*)"/g)) node.setAttribute(attr[1], attr[2]);
      stack.at(-1).append(node);
      if (!tag.endsWith('/') && !['INPUT', 'BR', 'HR', 'IMG', 'META', 'LINK'].includes(node.tagName)) stack.push(node);
    }
  }
  querySelectorAll(selector) {
    const matches = node => {
      if (selector.includes(':not(:disabled)') && node.disabled) return false;
      const basic = selector.replace(':not(:disabled)', '');
      if (basic.startsWith('.')) return node.classList.contains(basic.slice(1));
      if (basic.startsWith('[')) { const attribute = basic.slice(1, -1); return attribute.startsWith('data-') ? attribute.slice(5) in node.dataset : node.attributes.has(attribute); }
      return node.tagName.toLowerCase() === basic;
    };
    return this.children.flatMap(node => [...(matches(node) ? [node] : []), ...node.querySelectorAll(selector)]);
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] ?? null; }
  remove() { if (this.parentElement) this.parentElement.children = this.parentElement.children.filter(node => node !== this); this.parentElement = null; }
  focus() { if (globalThis.document) document.activeElement = this; }
  setPointerCapture() {} releasePointerCapture() {}
  getBoundingClientRect() { return { left: 0, top: 0, width: 1280, height: 720 }; }
  getContext() { return this.context ??= { commands: [], fillRect(){}, strokeRect(){},
    fillText(text){this.commands.push({kind:'fill',text,color:this.fillStyle,font:this.font});},
    strokeText(text){this.commands.push({kind:'stroke',text,color:this.strokeStyle,font:this.font});} }; }
}
