
(use-modules
 (gnu)
 (guix)
 (srfi srfi-1)
 (guix git-download)
 (guix transformations)
 (ice-9 popen)
 (ice-9 rdelim))
(use-service-modules desktop mcron networking spice ssh xorg sddm)
(use-package-modules bootloaders fonts wm terminals
                     package-management xdisorg xorg display-managers)

(define %source-dir (dirname (current-filename)))

(define %git-commit
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f2" OPEN_READ)))

(define (skip-git-and-build-directory file stat)
  "Skip the `.git` and `build` directory when collecting the sources."
  (let ((name (basename file)))
    (not (or (string=? name ".git") (string=? name "build")))))

(define guix-simplyblack-sddm-theme-git
  (package
    (inherit guix-simplyblack-sddm-theme)
    (name "guix-simplyblack-sddm-theme-git")
    (version (git-version (package-version guix-simplyblack-sddm-theme) "HEAD" %git-commit))
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? skip-git-and-build-directory))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils)
                      (srfi srfi-26))
         (let* ((out (assoc-ref %outputs "out"))
                (themes-dir
                 (string-append out "/share/sddm/themes/guix-simplyblack-sddm/")))
           (mkdir-p themes-dir)
           (copy-recursively
            (assoc-ref %build-inputs "source")
            themes-dir)
           (substitute* (map (cut string-append themes-dir <>) '("Main.qml" "theme.conf"))
             (("file:")
              themes-dir))))))))


(operating-system
  (host-name "gnu")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")
  (keyboard-layout (keyboard-layout "eu"))

  ;; Label for the GRUB boot menu.
  (label (string-append "GNU Guix "
                        (or (getenv "GUIX_DISPLAYED_VERSION")
                            (package-version guix))))

  (firmware '())

  ;; Below we assume /dev/vda is the VM's hard disk.
  ;; Adjust as needed.
  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets '("/dev/vda"))
               (terminal-outputs '(console))))
  (file-systems (cons (file-system
                        (mount-point "/")
                        (device "/dev/vda1")
                        (type "ext4"))
                      %base-file-systems))

  (users (cons (user-account
                (name "guest")
                ;; sddm needs a password to work
                (password (crypt "guix" "$6$abc"))
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  ;; Our /etc/sudoers file.  Since 'guest' initially has an empty password,
  ;; allow for password-less sudo.
  (sudoers-file (plain-file "sudoers" "\
root ALL=(ALL) ALL
%wheel ALL=NOPASSWD: ALL\n"))
  (packages
   (append (list font-bitstream-vera
                 ;; Auto-started script providing SPICE dynamic resizing for
                 ;; Xfce (see:
                 ;; https://gitlab.xfce.org/xfce/xfce4-settings/-/issues/142).
                 x-resize
                 alacritty
                 i3-wm)
           %base-packages))

  (services
   (cons*
     (service sddm-service-type
              (sddm-configuration
               (theme "guix-simplyblack-sddm")
               (themes-directory
                (file-append guix-simplyblack-sddm-theme-git "/share/sddm/themes"))))
     ;; Add support for the SPICE protocol, which enables dynamic
     ;; resizing of the guest screen resolution, clipboard
     ;; integration with the host, etc.
     (service spice-vdagent-service-type)
     (modify-services
         %desktop-services
       (delete gdm-service-type))))
  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
