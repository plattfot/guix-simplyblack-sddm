;; SPDX-FileCopyrightText: 2023 Fredrik Salomonsson <plattfot@posteo.net>
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(use-modules
  (guix packages)
  (guix git-download)
  (guix gexp)
  (guix build-system gnu)
  ((guix licenses) #:prefix license:)
  (gnu packages display-managers)
  (gnu packages guile)
  (gnu packages pkg-config)
  (gnu packages texinfo)
  (gnu packages xdisorg)
  (gnu packages gnupg)
  (ice-9 popen)
  (ice-9 rdelim)
  )

(define %source-dir (dirname (current-filename)))

(define %git-commit
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f2" OPEN_READ)))

(define (skip-git-and-build-directory file stat)
  "Skip the `.git` and `build` directory when collecting the sources."
  (let ((name (basename file)))
    (not (or (string=? name ".git") (string=? name "build")))))

(package
  (inherit guix-simplyblack-sddm-theme)
  (name "guix-simplyblack-sddm-theme-git")
  (version (git-version (package-version guix-simplyblack-sddm-theme) "HEAD" %git-commit))
  (source (local-file %source-dir
                      #:recursive? #t
                      #:select? skip-git-and-build-directory)))
