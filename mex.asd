;;;; -*- lisp -*-

(defpackage #:mex-system
  (:use #:cl #:asdf)
  (:export #:%prologue%))
(in-package #:mex-system)


(defvar %prologue% ""
  "Code to run at start of Mex processing.")

(defclass load-mex-prologue-op (operation)
  ())

(defmethod output-files ((op load-mex-prologue-op) component)
  (values nil nil))

(defmethod perform ((op load-mex-prologue-op) component)
  (let ((mex-file (car (input-files op component))))
    (setq %prologue%
          (or (ignore-errors
                (with-open-file (in mex-file)
                  (with-output-to-string (out)
                    (loop for c := (read-char in nil nil) while c
                       do (write-char c out)))))
              ""))))

(defmethod operation-done-p ((op load-mex-prologue-op) component)
  nil)

(defun write-js (js-file)
  (let ((writer (ignore-errors
                  (symbol-function
                    (find-symbol "WRITE-JS" (find-package "MEX"))))))
    (when writer (funcall writer js-file))))

(defsystem #:mex
  :name "Mex"
  :author "Boris Smilga <boris.smilga@gmail.com>"
  :maintainer "Boris Smilga <boris.smilga@gmail.com>"
  :licence "BSD"
  :description "A macro processor for Web authoring" 
  :depends-on (#:parenscript #:cl-unicode #:cl-json)
  :components
    ((:static-file "mex.asd")
     (:module #:src
        :serial t
        :pathname ""
        :components
          ((:file "package")
           (:file "ambi-ps")
           (:file "ccat")
           (:file "context")
           (:file "token")
           (:file "group")
           (:file "command")
           (:file "core")
           ;(:file "memory")
           (:static-file "prologue.mex")
           (:file "mex"
              :in-order-to ((compile-op
                             (load-mex-prologue-op "prologue.mex")))))
        :perform (compile-op :after (op src)
                   (write-js
                     (merge-pathnames "mex.js"
                                      (component-pathname src)))))))
