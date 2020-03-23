(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-names-vector
   ["#212526" "#ff4b4b" "#b4fa70" "#fce94f" "#729fcf" "#ad7fa8" "#8cc4ff" "#eeeeec"])
 '(custom-enabled-themes (quote (tango-dark)))
 '(custom-safe-themes
   (quote
    ("1b8d67b43ff1723960eb5e0cba512a2c7a2ad544ddb2533a90101fd1852b426e" default)))
 '(gdb-many-windows t)
 '(gdb-show-main t)
 '(global-linum-mode t)
 '(helm-mode t)
 '(menu-bar-mode nil)
 '(package-selected-packages
   (quote
    (iedit function-args company-c-headers company helm-gtags ag helm-ag ac-helm nlinum ace-window)))
 '(tool-bar-mode nil)
 '(tooltip-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;(global-hl-line-mode)
;;(set-face-background hl-line-face 
(add-to-list 'load-path "~/.emacs.d/lisp")
(global-linum-mode)

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(global-set-key (kbd "C-x o") 'ace-window)
(require 'multi-term)

(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
(global-set-key (kbd "C-x C-f") #'helm-find-files)
(global-set-key (kbd "C-x b") #'helm-buffers-list)
(global-set-key (kbd "C-x p") #'helm-show-kill-ring)
(helm-mode 1)


;; indenting
(setq-default c-default-style "gnu"
              c-basic-offset 4)
(add-hook 'c-mode-common-hook '(lambda () (c-toggle-auto-state 1)))

(require 'company)
(add-hook 'after-init-hook 'global-company-mode)


(projectile-mode +1)
(define-key projectile-mode-map (kbd "s-p") `projectile-command-map)
(define-key projectile-mode-map (kbd "C-c p") `projectile-command-map)
