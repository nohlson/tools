(setq inhibit-startup-message t)

(scroll-bar-mode -1)                   ; Disable visible scrollbar
(tool-bar-mode -1)                     ; Disable the toolbar
(tooltip-mode -1)                      ; Disable tooltips
(set-fringe-mode 10)                   ; Give some breathing room

(menu-bar-mode -1)                     ; Disable the menu bar

(setq c-default-style "linux")

(defun my-c++-mode-hook ()
  (setq c-basic-offset 4)
  (c-set-offset 'substatement-open 0))
(add-hook 'c++-mode-hook 'my-c++-mode-hook)


;; Disable the bell entirely (visible-bell showed a caution-icon flash on macOS GUI)
(setq visible-bell nil)
(setq ring-bell-function 'ignore)

(load-theme 'tango-dark)

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")
			 ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Use swiper to find
(use-package swiper
  :ensure t)

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
	 :map ivy-minibuffer-map
	 ("TAB" . ivy-alt-done)
	 ("C-j" . ivy-alt-done)
	 ("C-k" . ivy-previous-line)
	 :map ivy-switch-buffer-map
	 ("C-l" . ivy-done)
	 ("C-d" . ivy-switch-buffer-kill)
	 :map ivy-reverse-i-search-map
	 ("C-k" . ivy-previous-line)
	 ("C-d" . ivy-reverse-i-search-kill))
  :custom
  (ivy-height 40)
  (ivy-fixed-height-minibuffer t)
  :config
  (ivy-mode 1))

;; Get cool doom themes
(use-package doom-themes)

;; Set the theme
(load-theme 'doom-dark+' t)

;; Change modeline to use the doom modeline
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)))

;; Show line numbers
(global-display-line-numbers-mode t)

;; Disable line numbers for some modes. Depth 100 so this runs *after*
;; global-display-line-numbers-mode's own activation hook (which otherwise
;; re-enables it right after us) -- recalculating the gutter on every fast
;; terminal redraw was part of what made vterm feel janky.
(add-hook 'after-change-major-mode-hook
          (lambda ()
            (when (derived-mode-p 'org-mode 'term-mode 'eshell-mode 'shell-mode 'vterm-mode)
              (display-line-numbers-mode 0)))
          100)

;; Only show line numbers in code buffers
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Avoid GUI stutter on macOS when switching between buffers/windows that use
;; different fonts (e.g. icon fonts vs regular text) -- font-cache compaction
;; after GC is a known cause of jumpiness on window/buffer switch.
(setq inhibit-compacting-font-caches t)

;; Font. Hack Nerd Font Mono carries both the text and the icon glyphs, so
;; icons in TUIs (Claude Code, etc.) render from the *same* font as the
;; surrounding text. Mixing fonts is what made rows change height when an
;; icon blinked in and out, shifting everything around it.
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "Hack Nerd Font Mono" :height 115)
  ;; Anything still missing above falls back to the symbols font rather than
  ;; to an arbitrary system font with mismatched metrics.
  (when (member "Symbols Nerd Font Mono" (font-family-list))
    (set-fontset-font t 'unicode (font-spec :family "Symbols Nerd Font Mono") nil 'append)))

;; Claude Code draws its status bullet (U+23FA) and cycles its spinner through
;; several Dingbats star/asterisk chars (U+2721-U+2755, e.g. U+273B, U+2733,
;; U+2722). None of these exist in Hack Nerd Font Mono, so macOS resolves them
;; to proportional fallback fonts (STIX Two Math / Arial Unicode MS) that are
;; taller than the default. Emacs always grows a row to fit its tallest glyph
;; (unlike a real terminal, which just clips into a fixed cell), so every time
;; one of these blinked in, the whole buffer shifted. Fix: at display time
;; only, substitute each for a lookalike that Hack/Symbols Nerd Font Mono
;; actually has, built to the same monospace-cell metrics, so nothing here can
;; ever change row height. Written with \x escapes rather than literal glyphs
;; since several of these render invisibly in plain-text editors/tools.
(defconst my/vterm-glyph-substitutions
  (list
   (cons "\x23fa" ?\x25cf)             ; status bullet -> Hack's black circle
   (cons "[\x2721-\x2755]" ?\xf069)))  ; dingbat stars/asterisks -> nerd-font asterisk icon

(defun my/vterm-fix-oversized-glyphs (beg end _len)
  (when (derived-mode-p 'vterm-mode)
    (save-excursion
      (dolist (sub my/vterm-glyph-substitutions)
        (goto-char beg)
        (while (re-search-forward (car sub) end t)
          (compose-region (match-beginning 0) (match-end 0) (cdr sub)))))))
(add-hook 'vterm-mode-hook
          (lambda ()
            (add-hook 'after-change-functions #'my/vterm-fix-oversized-glyphs nil t)))

;; Use rainbow delimiters
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Use which key, helps to tell you what keybindings are available
(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package counsel  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-switch-buffer)
	 ("C-x C-f" . counsel-find-file)
	 ("C-M-l" . counsel-imenu)
	 ("M-y" . counsel-yank-pop)
	 :map minibuffer-local-map
	 ("C-r" . 'counsel-minibuffer-history)))

;; Ivy rich mode to get more information about keybindings
(use-package ivy-rich
  :init
  (ivy-rich-mode 1))

;; Helpful is better help pages for functions
(use-package helpful
  :ensure t
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))


;; General makes keybindings easier and custom global keybindings look into custom meta keys
(use-package general)

;; Use projectile for navigating projects
(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-x p" . projectile-command-map)
  :init
  (setq projectile-switch-project-action #'projectile-dired))


;; Use counsel for projectile stuff
(use-package counsel-projectile
  :config (counsel-projectile-mode))


;; Setup Magit
(use-package magit
  :commands (magit-status magit-get-current-branch)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; Set cursor to bar
(setq-default cursor-type 'bar)


;; Setup lsp mode to use Language Server Protocol
;; (use-package lsp-mode
;;   :commands (lsp lsp-deferred)
;;   :init
;;   (setq lsp-keymap-efix "C-c l")
;;   :config
;;   (lsp-enable-which-key-integration t))

;; (use-package lsp-mode
;;  :ensure t
;;  :commands lsp lsp-deferred
;;  :config
;;  (lsp-enable-which-key-integration t)
;;  :hook ((python-mode c-mode c++-mode) . lsp))

;; (use-package lsp-ui
;;  :ensure t
;;  :commands lsp-ui-mode)

;;(use-package company-lsp
;;  :ensure t
;;  :commands company-lsp
;;  :config (push 'company-lsp company-backends))

;; Use ccls
;; (use-package ccls
;;   :ensure t
;;   :config
;;   (setq ccls-executable "ccls")
;;   (setq lsp-prefer-flymake nil)
;;   (setq-default flycheck-disabled-checkers '(c/c++-clang c/c++-cppcheck c/c++-gcc))
;;   :hook ((c-mode c++-mode objc-mode) .
;;          (lambda () (require 'ccls) (lsp))))

;; (lsp-register-client
;;     (make-lsp-client :new-connection (lsp-tramp-connection "clangd")
;;                      :major-modes '(c++-mode)
;;                      :remote? t
;;                      :server-id 'clangd))

;; Tramp should use the path of the login user. This is mostly for remote language servers
(use-package tramp)
(add-to-list 'tramp-remote-path 'tramp-own-remote-path)

(use-package eglot
  :ensure t)
(add-hook 'cpp-mode 'eglot-ensure)
(add-hook 'c-mode 'eglot-ensure)
(add-hook 'python-mode 'eglot-ensure)

;; Disabled for now, revisit later
;; (use-package company
;;   :ensure t
;;   :hook
;;   (after-init . global-company-mode))

;; Set initial frame size at startup
(add-to-list 'default-frame-alist '(height . 100))
(add-to-list 'default-frame-alist '(width . 250))


;; Term modes setup
(use-package term
  :config
  (setq explicit-shell-file-name "bash")
  (setq term-prompt-regexp "^[^#$%>\\n]*[#$%>] *"))


;; inheritenv is required by vterm
(use-package inheritenv
  :ensure t)

(use-package vterm
  :ensure t
  :commands vterm
  :bind (:map vterm-mode-map
              ("C-c C-l" . (lambda () (interactive) (vterm-reset-cursor-point) (redraw-display))))
  :config
  (setq vterm-max-scrollback 10000)
  ;; Stop Emacs from re-centering the window on every spinner redraw, which
  ;; caused the whole buffer to bounce up and down while Claude was thinking
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local scroll-conservatively 101)
              (setq-local auto-window-vscroll nil)
              (setq-local bidi-display-reordering nil))))

;; Dropping a file onto a vterm buffer inserts its path as text (like iTerm),
;; instead of Emacs' default of opening it as a new buffer.
(with-eval-after-load 'dnd
  (defun my/dnd-open-file-or-send-to-vterm (uri action)
    (let ((file (dnd-get-local-file-name uri t)))
      (if (and file (with-current-buffer (window-buffer (selected-window))
                      (derived-mode-p 'vterm-mode)))
          (with-current-buffer (window-buffer (selected-window))
            (vterm-send-string (shell-quote-argument file) t)
            (vterm-send-string " "))
        (dnd-open-file uri action))))
  (setcdr (assoc "^file:" dnd-protocol-alist) #'my/dnd-open-file-or-send-to-vterm))

;; Launch `claude` in a new vterm in the current directory, buffer named
;; after that directory so multiple sessions in different projects are
;; distinguishable in the buffer list. Chains `exit` after claude quits so
;; the underlying shell terminates too -- vterm-kill-buffer-on-exit (t by
;; default) then kills the buffer/window automatically.
(defun claude ()
  (interactive)
  (let* ((dir (file-name-nondirectory (directory-file-name default-directory)))
         (buf (vterm (generate-new-buffer-name (format "*%s-claude*" dir)))))
    (with-current-buffer buf
      (vterm-send-string "claude; exit")
      (vterm-send-return))))

;; Directional window switching under C-x, mirroring the C-p/C-n/C-b/C-f
;; up/down/left/right convention already used for cursor movement.
(global-set-key (kbd "C-x P") #'windmove-up)
(global-set-key (kbd "C-x N") #'windmove-down)
(global-set-key (kbd "C-x B") #'windmove-left)
(global-set-key (kbd "C-x F") #'windmove-right)

;; Shorter binding for the built-in kill-buffer-and-window (default C-x 4 0)
(global-set-key (kbd "C-x j") #'kill-buffer-and-window)

;; Show column number in all buffers
(setq column-number-mode t)

;; Ask (default no) to revert a file-visiting buffer when its file changed on disk.
;; Tracks the disk modtime we last asked about, so declining doesn't re-prompt
;; on every subsequent buffer switch -- only when the file changes again.
(defvar-local my/last-asked-revert-modtime nil)
(defun my/maybe-revert-buffer-on-switch ()
  (when (and buffer-file-name
             ;; buffer-list-update-hook also fires when unrelated code (modeline
             ;; segments, minor modes, etc.) transiently visits this buffer via
             ;; set-buffer without it ever being displayed -- only prompt when
             ;; this buffer is actually the one shown in the selected window.
             (eq (current-buffer) (window-buffer (selected-window)))
             (file-exists-p buffer-file-name)
             (not (verify-visited-file-modtime (current-buffer))))
    (let ((disk-modtime (file-attribute-modification-time
                          (file-attributes buffer-file-name))))
      (unless (equal disk-modtime my/last-asked-revert-modtime)
        (setq my/last-asked-revert-modtime disk-modtime)
        (when (yes-or-no-p (format "%s changed on disk. Revert? " (buffer-name)))
          (revert-buffer t t t))))))
(add-hook 'buffer-list-update-hook #'my/maybe-revert-buffer-on-switch)


;; Disable x window dialog boxes to attempt to fix crashes
(defadvice yes-or-no-p (around prevent-dialog activate)
  "Prevent yes-or-no-p from activating a dialog"
  (let ((use-dialog-box nil))
    ad-do-it))
(defadvice y-or-n-p (around prevent-dialog-yorn activate)
  "Prevent y-or-n-p from activating a dialog"
  (let ((use-dialog-box nil))
    ad-do-it))

;; Use smex to have counsel-M-x show most recent commands first
(use-package smex)


;; eshell config
(defun efs/configure-eshell ()
	;; Save command history when commands are entered
	(add-hook 'eshell-save-some-history)

	;; Truncate buffer for performance
	(add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

	(setq eshell-history-size         10000
	      eshell-buffer-maximum-lines 10000
	      eshell-hist-ignoredups t
	      eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt)

(use-package eshell
  :hook (eshell-first-time-mode . efs/configure-eshell)
  :config
  (eshell-git-prompt-use-theme 'powerline))

(use-package dired-single)

;; Dired
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :config
  (with-eval-after-load 'dired
    (bind-keys
     ;; Use dired single to keep all dired instances in the same buffer
     :map dired-mode-map
     ("<return>" . dired-single-buffer)
     ("<double-mouse-1>" . dired-single-buffer-mouse)
     ("^" . dired-single-up-directory))))

;; Get icons in dired
(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

;; nerd-icons: doom-modeline and other modern packages use this instead of all-the-icons
(use-package nerd-icons
  :ensure t)

;; Automatically update packages
(use-package auto-package-update
  :custom
  (auto-package-update-interval 7)
  (auto-package-update-prompt-before-update t)
  (auto-package-update-hide-results t)
  :config
  (auto-package-update-maybe)
  (auto-package-update-at-time "11:00"))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(eat swift3-mode conda claude-code gptel exec-path-from-shell minuet dash plz pdf-tools auto-package-update all-the-icons-dired dired-single eshell-git-prompt smex vterm company magit counsel-projectile projectile general helpful ivy-rich counsel which-key rainbow-delimiters doom-modeline doom-themes swiper)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Send C-c to vterm
;; (define-key vterm-mode-map (kbd "C-c C-c") 'vterm-send-C-c)

;; ============================================
;; EMACS AI SETUP - OpenAI for completions, Claude Pro for Claude Code
;; ============================================

;; Bootstrap function for GitHub packages
(defun my/ensure-github-package (name repo)
  "Ensure a GitHub package is installed in site-lisp."
  (let ((package-dir (expand-file-name 
                     (concat "site-lisp/" name) 
                     user-emacs-directory)))
    (unless (file-exists-p package-dir)
      (message "Installing %s from GitHub..." name)
      (make-directory (file-name-directory package-dir) t)
      (shell-command 
       (format "git clone https://github.com/%s.git %s" 
               repo 
               package-dir)))
    (add-to-list 'load-path package-dir)))

;; Inherit shell variables for OpenAI
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)
    (exec-path-from-shell-copy-env "OPENAI_API_KEY")))

;; CONDA ENVIRONMENT MANAGEMENT
(use-package conda
  :ensure t
  :init
  ;; Set the path to your conda installation (adjust if different)
  (setq conda-anaconda-home (expand-file-name "~/miniconda3"))
  (setq conda-env-home-directory (expand-file-name "~/miniconda3"))
  :config
  ;; Activate conda for the session
  (conda-env-initialize-interactive-shells)
  (conda-env-initialize-eshell)
  ;; Auto-activate conda in python-mode buffers
  (conda-env-autoactivate-mode t)
  ;; Bind key for quick environment switching
  (global-set-key (kbd "C-c C-e") 'conda-env-activate))

;; MINUET - Inline code completion with OpenAI
;; Disabled for now, revisit later
;; (use-package minuet
;;   :ensure t
;;   :init
;;   (setq minuet-provider 'openai)
;;   (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode)
;;
;;   :bind (("M-i"   . minuet-show-suggestion)
;;          ("C-c m" . minuet-configure-provider)
;;          :map minuet-active-mode-map
;;          ("M-p" . minuet-previous-suggestion)
;;          ("M-n" . minuet-next-suggestion)
;;          ("M-A" . minuet-accept-suggestion)
;;          ("M-a" . minuet-accept-suggestion-line)
;;          ("M-e" . minuet-dismiss-suggestion))
;;
;;   :config
;;   (plist-put minuet-openai-options :model "gpt-4o-mini")
;;   (plist-put minuet-openai-options :api-key
;;              (lambda () (getenv "OPENAI_API_KEY")))
;;   (minuet-set-optional-options minuet-openai-options :max_tokens 128))

;; eat: pure-elisp terminal, handles resize/redraw more robustly than vterm
(use-package eat
  :ensure t)

;; Auto-install claude-code from GitHub
(my/ensure-github-package "claude-code.el" "stevemolitor/claude-code.el")

;; CLAUDE CODE - Load explicitly with require
(require 'claude-code)

;; Configure Claude Code (defaults to eat backend)

(when (fboundp 'setopt)
  (setopt vterm-min-window-width 40))

;; Bind keys for Claude Code
(global-set-key (kbd "C-c a c") 'claude-code)
(global-set-key (kbd "C-c a k") 'claude-code-kill)
(global-set-key (kbd "C-c a m") 'claude-code-transient)
(global-set-key (kbd "C-c a r") 'claude-code-resume)

;; GPTEL - Quick inline prompting with OpenAI
(use-package gptel
  :ensure t
  :bind (("C-c a g" . gptel-send)
         ("C-c a q" . gptel)
         ("C-c a r" . gptel-rewrite-menu))
  :init
  ;; Set defaults before loading
  (setq gptel-model "gpt-4o-mini")
  :config
  ;; Configure after package loads
  (setq gptel-backend 
        (gptel-make-openai "ChatGPT"
          :stream t
          :models '("gpt-4o-mini" "gpt-4o" "gpt-3.5-turbo")
          :key (lambda () (getenv "OPENAI_API_KEY")))))

;; ============================================
;; WORKFLOW HELPERS
;; ============================================

(defun my/cursor-layout ()
  "Set up Cursor-like layout: code on left, Claude Code on right."
  (interactive)
  (delete-other-windows)
  (split-window-right)
  (other-window 1)
  (claude-code)
  (other-window 1))

(global-set-key (kbd "C-c w c") 'my/cursor-layout)

(defun my/send-to-claude-code ()
  "Copy current region or function to kill ring with instruction prefix."
  (interactive)
  (let* ((text (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (thing-at-point 'defun t)))
         (filename (buffer-file-name))
         (instruction (read-string "Instruction for Claude: ")))
    (when text
      (let ((prompt (format "%s\n\nFile: %s\n\n```\n%s\n```"
                           instruction
                           (or filename "current buffer")
                           text)))
        (kill-new prompt)
        (message "Copied to kill ring. Paste into Claude Code with C-y")))))

(global-set-key (kbd "C-c a p") 'my/send-to-claude-code)


;; Put frame in focused window
;; Don't save frame position - let macOS decide
(setq frame-inhibit-implied-resize t)

;; Remove desktop-save-mode if you have it
;; (desktop-save-mode -1)

;; Function to center Emacs on current display
(defun my/center-frame-on-current-display ()
  "Center Emacs frame on the display where mouse is."
  (interactive)
  (let* ((frame (selected-frame))
         (workarea (frame-monitor-workarea frame))
         (left (nth 0 workarea))
         (top (nth 1 workarea))
         (width (nth 2 workarea))
         (height (nth 3 workarea))
         (frame-width (frame-pixel-width))
         (frame-height (frame-pixel-height))
         (new-left (+ left (/ (- width frame-width) 2)))
         (new-top (+ top (/ (- height frame-height) 2))))
    (set-frame-position frame new-left new-top)))

;; Center frame on launch
(add-hook 'after-init-hook 'my/center-frame-on-current-display)

;; Bind to a key for manual centering
(global-set-key (kbd "C-c w m") 'my/center-frame-on-current-display)

;; Include command to start claude code dangerously
(defun claude-code-start-dangerous ()
  "Launch Claude Code with permissions skipped."
  (interactive)
  (let ((process-environment (cons "CLAUDE_BYPASS_PERMISSIONS=true" process-environment)))
    (call-interactively 'claude-code-start-in-directory)))
