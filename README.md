# Guix simply black theme for SDDM

A simple theme for SDDM.

Based on the [Arch Linux theme for SDDM](https://github.com/Guidobelix/archlinux-themes-sddm).

# Usage

Install the `guix-simplyblack-sddm-theme` guix package to your system
configuration and set `guix-simplyblack-sddm` as the theme in the
`sddm-configuration`.

# Testing

For development run the following command in a bash compatible shell:

```bash
    guix shell sddm -- sddm-greeter-qt6 --test-mode --theme $(guix build -f guix.scm)/share/sddm/themes/guix-simplyblack-sddm
```

For Qt5 you can run:
```bash
    guix shell sddm-qt5 -- sddm-greeter --test-mode --theme $(guix build -f guix.scm)/share/sddm/themes/guix-simplyblack-sddm

```
