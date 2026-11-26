;;; calfw-dst-test.el --- dt to st test: dump org sources to text and diff  -*- lexical-binding: t; -*-

;;; Commentary:

;; Writes an org fixture to OUT-DIR, opens a calfw calendar on it (once
;; through the org-agenda-style source and once through the file source), and
;; dumps each calendar to a text file in OUT-DIR.  The ERT tests compare those
;; dumps with the reference files.
;;
;; Run with:
;;   emacs --batch -L . -L tests/ -l tests/calfw-dst-test.el --eval "(calfw-dst-test-dump \"calfw-dst-test\" \"* Event 1\n<2026-11-01 Sun>\n\" \"tests/outputs/calfw-dst-test/calfw-dst-test/\")"

;;; Code:

(require 'ert)
(require 'calfw)
(require 'calfw-org)
(require 'utils)

(defconst tests-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory this test file lives in.")

(defconst test-file-name "calfw-dst-test"
  "Name of this test file, used to build its outputs and refs directories.")

(defun org-text-to-cal-dump (test-name render-date org-content out-dir)
  "Dump the create-source and file-source calendars of ORG-CONTENT into OUT-DIR.
TEST-NAME prefixes the output file names.  OUT-DIR is created if needed, and
any existing dumps in it are replaced. DATE is the date to show, in the form
(month day year), e.g. (11 3 2026)."

  ;; Batch Emacs has no real default colors, so `calfw-composite-color'
  ;; would get "unspecified-bg"/"unspecified-fg" and fail.  Pin both so the
  ;; colors resolve.
  (set-face-background 'default "#000000")
  (set-face-foreground 'default "#ffffff")
  (let* ((source-org (expand-file-name (concat test-name "-cal.org") out-dir))
         (create-source-out (expand-file-name (concat test-name "-create-source.cal") out-dir))
         (create-file-source-out (expand-file-name (concat test-name "-create-file-source.cal") out-dir)))
    (make-directory out-dir t)
    (dolist (file (list source-org create-source-out create-file-source-out))
      (when (file-exists-p file)
        (delete-file file)))
    (with-temp-file source-org (insert org-content))
    (calfw-test--sources-to-file render-date
     (list (calfw-org-create-source (list source-org) "Org:my-calendar" "Seagreen4"))
     create-source-out)
    (calfw-test--sources-to-file render-date
     (list (calfw-org-create-file-source "my-calendar" source-org "Seagreen4"))
     create-file-source-out)))

(ert-deftest calfw-dst-fallback-test ()
  "Dumps the fallback fixture and checks it against the references."
  (let* ((test-name "calfw-dst-fallback-test")
         (out-dir (expand-file-name (concat "outputs/" test-file-name "/" test-name "/") tests-dir))
         (refs-dir (expand-file-name (concat "refs/" test-file-name "/" test-name "/") tests-dir)))
    (org-text-to-cal-dump test-name '(11 3 2026) "
* Event 1
<2026-10-31 Sat>--<2026-11-02 Mon>
* Event 2
<2026-10-31 Sat>--<2026-11-01 Sun>
* Event 3
<2026-11-01 Sun>--<2026-11-02 Mon>
" out-dir)
    (should-not (calfw-test--mismatches refs-dir out-dir))))

(ert-deftest calfw-dst-springforward-test ()
  "Dumps the spring-forward fixture and checks it against the references."
  (let* ((test-name "calfw-dst-springforward-test")
         (out-dir (expand-file-name (concat "outputs/" test-file-name "/" test-name "/") tests-dir))
         (refs-dir (expand-file-name (concat "refs/" test-file-name "/" test-name "/") tests-dir)))
    (org-text-to-cal-dump test-name '(3 14 2026) "
* Event 0
<2026-02-27 Fri>--<2026-03-11 Wed>
* Event 1
<2026-03-08 Sun>--<2026-03-09 23:30:00>
* Event 2
<2026-03-08 Sun 09:30:00>--<2026-03-08 Sun 10:30:00>
* Event 3
<2026-03-08 Sun 09:30:00>--<2026-03-09 Mon 10:30:00>
" out-dir)
    (should-not (calfw-test--mismatches refs-dir out-dir))))

(provide 'calfw-dst-fallback-test)
;;; calfw-dst-test.el ends here
