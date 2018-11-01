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

(add-hook 'smerge-mode-hook
  (lambda ()
    (define-key smerge-mode-map (kbd "<f2>") 'smerge-prev)
    (define-key smerge-mode-map (kbd "<f3>") 'smerge-next)
    (define-key smerge-mode-map (kbd "<f4>") 'smerge-keep-current)
    (define-key smerge-mode-map (kbd "<f5>") 'smerge-keep-mine)
    (define-key smerge-mode-map (kbd "<f6>") 'smerge-keep-other)
    (define-key smerge-mode-map (kbd "<f7>") 'smerge-keep-all)
    (define-key smerge-mode-map (kbd "<f8>") 'smerge-swap)
    (define-key smerge-mode-map (kbd "<f9>") 'smerge-ediff)))

(global-set-key (kbd "<f10>") 'save-and-close)
(global-set-key (kbd "<f11>") (lambda () (interactive) (find-file "~/.emacs")))
(global-set-key (kbd "<f12>") (lambda () (interactive) (kill-emacs 1)))

(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)
(setq inhibit-startup-buffer-menu t)
(setq ring-bell-function 'ignore)
(setq-default show-trailing-whitespace t)

(require 'hlinum)
(hlinum-activate)
(global-linum-mode t)
(setq linum-format "%4d \u2502 ")

(which-function-mode 1)
(electric-indent-mode -1)

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

;; xemacs stuff
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(load-home-init-file t t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(linum-highlight-face ((t (:inherit default :foreground "cyan" :weight bold)))))
