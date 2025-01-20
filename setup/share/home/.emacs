;; FIXME: 256 colors work only in xterm-256color:
;; screen.xterm-256color and my custom TERM=screen should be merged
;; into xterm-256color
;; Use (list-colors-display) to test colors

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(setq package-check-signature nil)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; FIXME: these are not detected by TERM=screen.xterm-256color though
;; they work in xterm-256color and tack displays them properly under
;; both terms. tack output:
;; ^[[1;2A    (kri) (kUP)
;; ^[[1;2B    (kind) (kDN)
;; bash also doesn't detect them properly (prints A, B under
;; screen.xterm; prints nothing under xterm).
(define-key input-decode-map "\e[1;2A" [S-up])
(define-key input-decode-map "\e[1;2B" [S-down])

(global-set-key (kbd "<mouse-4>") 'scroll-down-line)
(global-set-key (kbd "<mouse-5>") 'scroll-up-line)
;; TERM=xterm-256color breaks End key
;; but 256 colors work only with this xterm-256color
(global-set-key (kbd "<select>") 'end-of-line)
(xterm-mouse-mode 1)

(defun save-and-close ()
  "<undocumented>"
  (interactive)
  (when buffer-file-name
    (save-buffer)
    (kill-buffer)
    (let ((buffers (buffer-list)) found)
      (while buffers
        (when (with-current-buffer (car buffers) buffer-file-name)
          (switch-to-buffer (car buffers))
          (setq buffers nil)
          (setq found 1))
        (setq buffers (cdr buffers)))
      (unless found
        (kill-emacs)))))

;; (defun my-auto-revert-with-cursor ()
;;   "Auto-revert buffer while preserving cursor position."
;;   (let ((pos (point)))
;;     (revert-buffer t t)
;;     (goto-char pos)))

;;(add-hook 'auto-revert-mode-hook
;;          (lambda ()
;;            (setq revert-buffer-function 'my-auto-revert-with-cursor)))

(add-hook 'smerge-mode-hook
  (lambda ()
    (auto-revert-mode 1)
    (define-key smerge-mode-map (kbd "<f2>") 'smerge-prev)
    (define-key smerge-mode-map (kbd "<f3>") 'smerge-next)
    (define-key smerge-mode-map (kbd "<f4>") 'smerge-keep-current)
    (define-key smerge-mode-map (kbd "<f5>") 'smerge-keep-mine)
    (define-key smerge-mode-map (kbd "<f6>") 'smerge-keep-other)
    (define-key smerge-mode-map (kbd "<f7>") 'smerge-keep-all)
    (define-key smerge-mode-map (kbd "<f8>") 'smerge-swap)
    (define-key smerge-mode-map (kbd "<f9>") 'smerge-refine)))

(global-set-key (kbd "<f10>") 'save-and-close)
(global-set-key (kbd "<f11>") (lambda () (interactive) (find-file "~/.emacs")))
(global-set-key (kbd "<f12>") (lambda () (interactive) (kill-emacs 1)))
(global-set-key (kbd "<f23>") (lambda () (interactive) (switch-to-buffer "*scratch*")))

(with-eval-after-load 'git-rebase
  (define-key git-rebase-mode-map (kbd "<f10>")
    (lambda () (interactive)
      (save-buffer)
      (with-editor-finish t)
      (save-buffers-kill-terminal)))
  (define-key git-rebase-mode-map (kbd "C-k") 'kill-line)
  (define-key git-rebase-mode-map (kbd "C-y") 'yank))

(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq inhibit-startup-buffer-menu t)
(setq ring-bell-function 'ignore)
(setq-default show-trailing-whitespace t)
(setq scroll-step 1 scroll-conservatively  10000)

;; words include dashes
(add-hook 'after-change-major-mode-hook
  (lambda ()
    (modify-syntax-entry ?- "w")))

;; navigate words skipping spaces
(require 'misc)
(global-set-key (kbd "s-f") 'forward-word)
(global-set-key (kbd "s-b") 'backward-to-word)
(global-set-key (kbd "M-f") 'forward-to-word)

;; kill space after word
(defun kill-whitespace ()
  "If `point' is followed by whitespace kill that.
Otherwise call `kill-word'"
  (interactive)
  (when (looking-at "[ \t\n]")
      (let ((pos (point)))
        (re-search-forward "[^ \t\n]" nil t)
        (backward-char)
        (kill-region pos (point)))))

;; FIXME: doesn't work
(defun kill-whitespace-word ()
  "<undocumented>"
  (interactive)
  (unless (kill-whitespace)
    (kill-word)))

;;(global-set-key (kbd "M-d") 'kill-whitespace-word)

(require 'hlinum)
(hlinum-activate)
(global-linum-mode t)
(setq linum-format "%4d \u2502 ")

(which-function-mode 1)
(electric-indent-mode -1)
(column-number-mode 1)

(defun display-startup-echo-area-message ()
  (message ""))

(add-hook 'emacs-startup-hook
  (lambda ()
    (delete-other-windows)
    (let ((buffers (buffer-list)) (file-count 0))
    (while buffers
      (when (with-current-buffer (car buffers) buffer-file-name)
        (setq file-count (1+ file-count)))
      (setq buffers (cdr buffers)))
    (when (> file-count 0)
      (message  (concat "You have " (number-to-string file-count) " files")))))
  t)

(add-to-list 'auto-mode-alist '("\\.yy\\'" . c++-mode))

(defun check-smerge-mode ()
  "<undocumented>"
  (interactive)
  (when (and buffer-file-name (vc-backend buffer-file-name))
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " nil t)
        (smerge-mode +1))))

(add-hook 'after-change-major-mode-hook 'check-smerge-mode)

;; Save all tempfiles in $TMPDIR/emacs$UID/
(defconst emacs-tmp-dir (format "%s/%s-%s/"
  (if (file-accessible-directory-p "/var/tmp")
    "/var/tmp"
    (if small-temporary-file-directory
      small-temporary-file-directory
      temporary-file-directory))
  "emacs" (user-uid)))

(setq backup-directory-alist
    `((".*" . ,emacs-tmp-dir)))
(setq auto-save-file-name-transforms
    `((".*" ,emacs-tmp-dir t)))
(setq auto-save-list-file-prefix
    emacs-tmp-dir)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(load-home-init-file t t)
 '(package-selected-packages '(compat magit editorconfig cmake-mode))
 '(vc-follow-symlinks t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((t (:foreground "brightblack"))))
 '(font-lock-doc-face ((t (:inherit font-lock-comment-face))))
 '(font-lock-function-name-face ((t (:foreground "color-127"))))
 '(font-lock-keyword-face ((t (:foreground "color-208"))))
 '(font-lock-string-face ((t (:foreground "color-196"))))
 '(font-lock-type-face ((t (:foreground "color-26"))))
 '(linum-highlight-face ((t (:inherit default :foreground "cyan" :weight bold))))
 '(menu ((t (:background "color-17"))))
 '(minibuffer-prompt ((t (:foreground "color-82"))))
 '(mode-line ((t (:background "color-17" :foreground "brightwhite" :box (:line-width -1 :style released-button)))))
 '(mode-line-buffer-id ((t (:background "color-17" :foreground "color-199"))))
 '(smerge-lower ((t (:background "color-233"))))
 '(smerge-markers ((t (:background "color-233" :foreground "color-196"))))
 '(smerge-refined-added ((t (:inherit smerge-refined-change :foreground "red"))))
 '(smerge-refined-removed ((t (:inherit smerge-refined-change :foreground "red"))))
 '(smerge-upper ((t nil)))
 '(trailing-whitespace ((t (:background "color-233")))))

(setq scroll-error-top-bottom 't)
