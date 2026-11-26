;;; utils.el --- Shared utils for calfw-org tests  -*- lexical-binding: t; -*-

;;; Commentary:

;; Helpers used by the calfw-org-*-test.el files.  Not a test file itself.

;;; Code:

(require 'ert)
(require 'calfw-org)

(defun calfw-test--sources-to-file (date sources output-file)
  "Open a calendar with SOURCES at a fixed size and write its text to OUTPUT-FILE.
DATE is the date to show, in the form (month day year), e.g. (11 3 2026)."
  (let ((dims (cons 150 80)))
    (cl-letf (((symbol-function 'calfw-default-window-dims)
               (lambda (&optional _window) dims)))
      (calfw-open-calendar-buffer :date date :contents-sources sources)))
  (let ((text (buffer-substring-no-properties (point-min) (point-max))))
    (with-temp-file output-file (insert text "\n"))
    (kill-buffer (current-buffer))))

(defun calfw-test--read-file (file)
  "Return the contents of FILE as a string."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defun calfw-test--file-names (dir)
  "Return the sorted names of the regular files in DIR, or nil if DIR does not exist."
  (when (file-directory-p dir)
    (sort (seq-filter (lambda (name) (file-regular-p (expand-file-name name dir)))
                      (directory-files dir))
          #'string<)))

(defun calfw-test--mismatches (refs-dir outputs-dir)
  "Return a list of messages describing how REFS-DIR and OUTPUTS-DIR differ.
Every file in REFS-DIR must exist in OUTPUTS-DIR with the same contents.
Files that exist only in OUTPUTS-DIR are ignored."
  (let ((ref-names (calfw-test--file-names refs-dir))
        (out-names (calfw-test--file-names outputs-dir))
        problems)
    (dolist (name ref-names)
      (let ((ref (expand-file-name name refs-dir))
            (out (expand-file-name name outputs-dir)))
        (cond
         ((not (member name out-names))
          (push (format "%s: missing from outputs" name) problems))
         ((not (equal (calfw-test--read-file ref)
                      (calfw-test--read-file out)))
          (push (format "%s: differs from refs (try: delta -s %s %s)" name ref out)
                problems)))))
    (nreverse problems)))

(provide 'utils)
;;; utils.el ends here
