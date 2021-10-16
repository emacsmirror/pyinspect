;;; pyinspect.el -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Maor Kadosh
;;
;; Author: Maor Kadosh <https://github.com/ah>
;; Maintainer: Maor Kadosh <maorkdosh@gmail.com>
;; Created: October 15, 2021
;; Modified: October 15, 2021
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/ah/pyinspect
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;
;;
;;; Code:
(require 'python)

(defvar pyinspect--boilerplate "
from inspect import getmembers, ismethod
import json


def _pyinspect(obj):
    def underline_count(members):
        key, val = members
        type_weight = 3 if ismethod(val) else 0
        return key.count('_', 0, 2) * 2 + type_weight


    def stringify_vals(members):
        key, val = members
        return key, str(val)

    members = sorted(getmembers(obj), key=underline_count)
    members = map(stringify_vals, members)
    return print(json.dumps(dict(members)))")

(define-derived-mode pyinspect-mode special-mode "Python Inspector"
  (python-shell-send-string-no-output pyinspect--boilerplate)
  (set-syntax-table python-mode-syntax-table))

(defun pyinspect--make-key-callback (obj-name)
  "To be called when a field name of inspected object OBJ-NAME is clicked."
  (lambda (_btn)
    (pyinspect--inspect obj-name nil)))

(defun pyinspect--inspect-in-current-buffer (obj-name)
  "Inspect object OBJ-NAME in current pyinspect buffer."
  (let ((buffer-read-only nil)
        (members (json-read-from-string
                  (python-shell-send-string-no-output
                   (format "_pyinspect(%s)" obj-name)))))
    (erase-buffer)
    (cl-loop for (k . v) in members
             do
             (insert-button (symbol-name k)
                            'action (pyinspect--make-key-callback
                                     (format "%s.%s" obj-name k)))
             (insert " = " (if (equal "" v) "\"\"" v) "\n"))
    (goto-char (point-min))))

(defun pyinspect--inspect (obj-name pop)
  "Inspect OBJ-NAME in a new buffer.
If POP is non-nil, new buffer will be created with `pop-to-buffer'. Otherwise
replaces current buffer."
  (let ((buf-func (if pop #'pop-to-buffer #'generate-new-buffer))
        (buf-name (format "Pyinspect: %s" obj-name)))
    (funcall buf-func buf-name)
    (switch-to-buffer buf-name))
  (pyinspect-mode)
  (pyinspect--inspect-in-current-buffer obj-name))

(defun pyinspect-inspect-at-point ()
  "Inspect symbol at point in pyinspect-mode."
  (interactive)
  (pyinspect--inspect (symbol-at-point) 'pop))

(provide 'pyinspect)
;;; pyinspect.el ends here
