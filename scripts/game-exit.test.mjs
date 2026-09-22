import test from 'node:test';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';

class Element {
  tagName = 'DIV'; isContentEditable = false; children = [];
  append(...nodes) { this.children.push(...nodes); }
  replaceChildren(...nodes) { this.children = nodes; }
}
globalThis.HTMLElement = Element;
const { bindResetAndClose } = await importTypescript(new URL('../src/world/systems/resetAndClose.ts',import.meta.url));
const { World } = await importTypescript(new URL('../src/world/world.ts',import.meta.url));
function key(fields={}) {
  const event = new Event('keydown',{cancelable:true});
  Object.assign(event,{code:'Backspace',ctrlKey:true,shiftKey:true,altKey:false,metaKey:false,repeat:false,isComposing:false},fields);
  return event;
}

test('reset shortcut requires the exact chord, skips typing/repeats and resets before closing once', () => {
  globalThis.window = new EventTarget();
  const calls=[];const unbind=bindResetAndClose(()=>{calls.push('reset');return true;},()=>calls.push('close'));
  for(const fields of [{ctrlKey:false},{shiftKey:false},{altKey:true},{metaKey:true},{repeat:true},{isComposing:true},{code:'KeyR'}]) {
    const event=key(fields);window.dispatchEvent(event);assert.equal(event.defaultPrevented,false);
  }
  for(const fields of [{tagName:'INPUT'},{tagName:'TEXTAREA'},{tagName:'SELECT'},{isContentEditable:true}]) {
    const event=key();Object.defineProperty(event,'target',{value:Object.assign(new Element(),fields)});
    window.dispatchEvent(event);assert.equal(event.defaultPrevented,false);
  }
  assert.deepEqual(calls,[]);
  const event=key();window.dispatchEvent(event);assert.equal(event.defaultPrevented,true);
  window.dispatchEvent(key());assert.deepEqual(calls,['reset','close']);unbind();
});

test('failed reset reports an error without closing and the shortcut can be retried', () => {
  globalThis.window=new EventTarget();let succeeds=false,closes=0;const messages=[];
  window.alert=message=>messages.push(message);
  bindResetAndClose(()=>succeeds,()=>closes++);
  window.dispatchEvent(key());assert.equal(closes,0);assert.match(messages[0],/Could not reset/);
  succeeds=true;window.dispatchEvent(key());assert.equal(closes,1);
});

test('closing stops rendering and disposes controls before attempting tab closure, with a usable fallback', () => {
  for(const throws of [false,true]) {
    const calls=[],container=new Element();globalThis.window=new EventTarget();
    globalThis.document={pointerLockElement:container,exitPointerLock(){calls.push('unlock');},createElement(){return new Element();}};
    const world=Object.assign(Object.create(World.prototype),{
      container,closed:false,
      startScreen:{dispose(){calls.push('title');}},
      loop:{stop(){calls.push('stop');},start(){assert.fail('Closed game restarted');}},
      unbindReset(){calls.push('unbind');},tycoon:{dispose(){calls.push('tycoon');}},
      driving:{dispose(){calls.push('driving');}},resizer:{dispose(){calls.push('resizer');}},
      renderer:{dispose(){calls.push('renderer');},forceContextLoss(){calls.push('context');},render(){assert.fail('Closed game rendered');}},
    });
    window.close=()=>{
      calls.push('close');assert.equal(container.children[0].children[0].textContent,'Game closed');
      if(throws)throw Error('Browser refused closure');
    };
    world.close();world.close();world.start();world.render();
    assert.deepEqual(calls,['stop','title','unbind','tycoon','driving','resizer','unlock','renderer','context','close']);
    assert.match(container.children[0].children[1].textContent,/close this tab/);
  }
});
