(defpackage :nfft
  (:use #:cl))
(in-package :nfft)

(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload :cl-autowrap)
  (defparameter *spec-path* (merge-pathnames "stage/cl-c2ffi-nfft/"
					     (user-homedir-pathname))))

;; https://www-user.tu-chemnitz.de/~potts/nfft/guide3/html/node38.html

(autowrap:c-include "/usr/local/include/nfft3.h"
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
		    :trace-c2ffi t)

(cffi:load-foreign-library "/usr/local/lib/libnfft3.so")

;; try a 1d example (d=1)
(let ((nr-nonequi-nodes 128)
      (nr-fourier-coefs 128))
  (autowrap:with-alloc (plan 'nfft-plan)
    (unwind-protect
     (progn
       (nfft-init-1d plan nr-fourier-coefs nr-nonequi-nodes)
       (setf (nfft-plan.flags plan) +PRE-ONE-PSI+)
       (let* ((xl (loop for i below nr-nonequi-nodes collect
		       (+ (random .1) -.5 (* (/ 1d0 nr-nonequi-nodes) i))))
	      (x (make-array nr-nonequi-nodes :element-type 'double-float
			     :initial-contents xl)))
	 (sb-sys:with-pinned-objects (x)
	   (setf (nfft-plan.x plan) (sb-sys:vector-sap x))
	   (sb-int:with-float-traps-masked (:overflow :invalid)
	    (nfft-precompute-one-psi plan)))))
      (nfft-finalize plan))))
#+nil
(truncate
 (autowrap:foreign-record-bit-size
  (autowrap:find-type '(:struct (USBDEVFS-BULKTRANSFER))))
 8)
