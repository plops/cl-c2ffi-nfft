(defpackage :nfft
  (:use #:cl))
(in-package :nfft)

(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload :cl-autowrap)
  (defparameter *spec-path* (merge-pathnames "stage/cl-c2ffi-nfft/"
					     (user-homedir-pathname))))

;; https://www-user.tu-chemnitz.de/~potts/nfft/guide3/html/node38.html
(progn
  (with-open-file (s "/tmp/nfft0.h"
                     :direction :output
                     :if-does-not-exist :create
                     :if-exists :supersede)
    (format s "#include \"/usr/lib/gcc/x86_64-pc-linux-gnu/6.1.1/include/stddef.h\"~%") ;; ptrdiff_t
    ;;(format s "#define NFFT_INT int")
    (format s "#include \"/usr/local/include/nfft3.h\"~%"))
  (autowrap::run-check autowrap::*c2ffi-program*
                       (autowrap::list "/tmp/nfft0.h"
                                       "-D" "null"
                                       "-M" "/tmp/nfft_macros.h"
                                       "-A" "x86_64-pc-linux-gnu"))
  
  (with-open-file (s "/tmp/nfft1.h"
                     :direction :output
                     :if-does-not-exist :create
                     :if-exists :supersede)
    
    (format s "#include \"/tmp/nfft0.h\"~%")
    (format s "#include \"/tmp/nfft_macros.h\"~%")))

(autowrap:c-include "/tmp/nfft1.h"
                    :spec-path *spec-path*
                    :exclude-arch ("arm-pc-linux-gnu"
                                   "i386-unknown-freebsd"
                                   "i686-apple-darwin9"
                                   "i686-pc-linux-gnu"
                                   "i686-pc-windows-msvc"
                                   "x86_64-apple-darwin9"
                                        ;"x86_64-pc-linux-gnu"
                                   "x86_64-pc-windows-msvc"
                                   "x86_64-unknown-freebsd")
                    :exclude-sources ( "/usr/include/_G_config.h"
 "/usr/include/bits/stdio_lim.h"
 "/usr/include/bits/sys_errlist.h"
 "/usr/include/bits/types.h"
 "/usr/include/bits/typesizes.h"
 "/usr/include/bits/wordsize.h"
 "/usr/include/features.h"
 "/usr/include/fftw3.h"
 "/usr/include/gnu/stubs-64.h"
 "/usr/include/libio.h"
 "/usr/include/stdc-predef.h"
 "/usr/include/stdio.h"
 "/usr/include/sys/cdefs.h"
 "/usr/include/wchar.h")
		    :include-sources ("/usr/include/stddev.h")
                    :trace-c2ffi t)



(cffi:load-foreign-library "/usr/local/lib/libnfft3.so")

;; https://www-user.tu-chemnitz.de/~potts/nfft/guide3/html/node40.html
#+nil
(let ((d 1) ;; spatial dimension
      (N 14) ;; number of fourier coefficients
      (M 19) ;; number of non-equidistant nodes 
      )
  (autowrap:with-alloc (plan 'nfft-plan)
    (unwind-protect
     (progn
       (nfft-init-1d plan N M)
       (nfft-vrand-shifed-unit-double (nfft-plan.x plan)
				      (nfft-plan. plan))
       (setf (nfft-plan.flags plan) +PRE-ONE-PSI+)
       (let* ((xl (loop for i below M ;; *d  , values in -.5 .. .5
		     collect
		       (+ -.5 (* (/ 1d0 M) i))))
	      (x (make-array (length xl) :element-type 'double-float
			     :initial-contents xl))
	      (f-hat (make-array N :element-type '(complex double-float))))
	 (setf (aref f-hat 2) (complex .1d0))
	 (sb-sys:with-pinned-objects (x f-hat)
	   (setf (nfft-plan.x plan) (sb-sys:vector-sap x)
		 (nfft-plan. plan) (sb-sys:vector-sap f-hat))
	   (sb-int:with-float-traps-masked (:overflow :invalid)
	     (nfft-precompute-one-psi plan))
	   (nfft-trafo plan))))
      (nfft-finalize plan))))
#+nil
(truncate
 (autowrap:foreign-record-bit-size
  (autowrap:find-type '(:struct (USBDEVFS-BULKTRANSFER))))
 8)
