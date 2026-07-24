import { useEffect, useRef } from 'react';

const AUTOSAVE_DEBOUNCE_MS = 800;

/**
 * Debounced autosave — fires `onSave` AUTOSAVE_DEBOUNCE_MS after the last
 * change to `content`, and cancels in-flight timers on unmount.
 * This constant matches AppConstants.autosaveDebounce on the Flutter side
 * so both platforms behave identically.
 */
export function useAutosave(content: string, isDirty: boolean, onSave: (content: string) => void) {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!isDirty) return;

    if (timerRef.current) clearTimeout(timerRef.current);

    timerRef.current = setTimeout(() => {
      onSave(content);
    }, AUTOSAVE_DEBOUNCE_MS);

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [content, isDirty]);
}
