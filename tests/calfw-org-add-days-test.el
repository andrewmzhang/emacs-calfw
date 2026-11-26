;;; calfw-org-add-days-test.el --- Tests for calfw-org--add-days  -*- lexical-binding: t; -*-

;;; Commentary:

;; Checks that `calfw-org--add-days' moves a time by calendar days and keeps
;; the local wall-clock time, including across the DST changes in 2026.

;; How org-mode deals with spring forward:
;; There are 23 hrs on the day of spring forward
;; org handles missing hours in 2am by mapping it forward to 3am
;; Thus
;; (decode-time (encode-time 59 59 1 8 3 2026)) -> 1:59:59 am CST
;; (decode-time (encode-time 0 0 2 8 3 2026))   -> 3 am DST
;; (decode-time (encode-time 0 30 2 8 3 2026))  -> 3:30 am DST
;; (decode-time (encode-time 59 59 2 8 3 2026)) -> 3:59:59 am DST
;; (decode-time (encode-time 0 0 3 8 3 2026))   -> 3am CST
;;
;; How org-mode deals with fall back:
;; There are 25 hrs on the day of fall back
;; org favors DT over ST
;; Thus:
;; (decode-time (encode-time 59 59 0 1 11 2026)) -> 0:59:59am DT
;;
;; (encode-time 59 59 1 1 11 2026)
;; (encode-time 0 0 2 1 11 2026)

;;; Code:

(require 'ert)
(require 'calfw-org)

(defun calfw-org-add-days-test--format (time)
  "Return TIME formatted in local time as \"YYYY-MM-DD HH:MM:SS\"."
  (format-time-string "%F %T" time))

(ert-deftest calfw-org-add-days-test-zero-days ()
  "Adding zero days leaves the time unchanged."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 1 10 2026) 0))
                 "2026-10-01 00:00:00")))

(ert-deftest calfw-org-add-days-test-positive-days ()
  "Adding days moves forward by calendar days."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 1 10 2026) 1))
                 "2026-10-02 00:00:00")))

(ert-deftest calfw-org-add-days-test-negative-days ()
  "Adding a negative number of days moves backward by calendar days."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 1 10 2026) -1))
                 "2026-09-30 00:00:00")))

(ert-deftest calfw-org-add-days-test-fall-back-keeps-wall-clock ()
  "Crossing the November DST change keeps midnight, not 23:00 from a 24h offset."
  ;; Note there are 25 hours on 2026-11-01
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 1 11 2026) 1))
                 "2026-11-02 00:00:00")))

(ert-deftest calfw-org-add-days-test-spring-forward-keeps-wall-clock ()
  "Crossing the March DST change keeps the same wall-clock time."
  ;; Note there are 23 hours on 2026-03-08
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 12 7 3 2026) 1))
                 "2026-03-08 12:00:00")))

(ert-deftest calfw-org-add-days-test-preserves-time-of-day ()
  "Hours, minutes and seconds are carried over unchanged."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 30 45 13 1 11 2026) 2))
                 "2026-11-03 13:45:30")))

(ert-deftest calfw-org-add-days-test-month-rollover ()
  "Days past the end of a month roll into the next month."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 30 11 2026) 2))
                 "2026-12-02 00:00:00")))

(ert-deftest calfw-org-add-days-test-year-rollover ()
  "Days past the end of a year roll into the next year."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 31 12 2026) 1))
                 "2027-01-01 00:00:00")))

(ert-deftest calfw-org-add-days-missing-time ()
  "Days past the end of a year roll into the next year."
  (should (equal (calfw-org-add-days-test--format
                  (calfw-org--add-days (encode-time 0 0 0 31 12 2026) 1))
                 "2027-01-01 00:00:00")))


(provide 'calfw-org-add-days-test)
;;; calfw-org-add-days-test.el ends here
