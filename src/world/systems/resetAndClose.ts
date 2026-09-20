export const RESET_AND_CLOSE_SHORTCUT = 'Ctrl + Shift + Backspace';

/** Keep the destructive shortcut separate from movement and text-editing input. */
export function bindResetAndClose(reset: () => boolean, close: () => void): () => void {
  const keyDown = (event: KeyboardEvent) => {
    const target = event.target;
    if (event.code !== 'Backspace' || !event.ctrlKey || !event.shiftKey || event.altKey || event.metaKey
      || event.repeat || event.isComposing
      || target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    if (!reset()) {
      window.alert('Could not reset the save. The game is still open; check browser storage access and try again.');
      return;
    }
    unbind();
    close();
  };
  const unbind = () => window.removeEventListener('keydown', keyDown);
  window.addEventListener('keydown', keyDown);
  return unbind;
}
