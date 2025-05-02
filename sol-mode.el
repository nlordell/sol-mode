;;; sol-mode.el --- Major mode for editing Solidity code -*- lexical-binding: t -*-

;; Copyright © 2025 Nicholas Rodrigues Lordello <n@lordello.net>

;; Author:   Nicholas Rodrigues Lordello <n@lordello.net>
;; URL:      https://codeberg.org/nlordell/sol-mode
;; Keywords: solidity languages
;; Version:  0.0.1

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a GNU Emacs major mode for editing Solidity
;; code. Solidity is a statically-typed curly-braces programming
;; language designed for developing smart contracts that run on
;; Ethereum.

;;; References
;; https://github.com/ethereum/emacs-solidity/blob/master/solidity-mode.el
;; https://github.com/bbatsov/neocaml/blob/main/neocaml.el
;; https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode

;;; Code:

(require 'cc-langs)
(require 'treesit)

;;; -- Configuration --

(defgroup solidity nil
  "Major mode for editing Solidity code."
  :prefix "solidity-"
  :group 'langauges)

(defcustom solidity-indent-offset 2
  "Number of spaces for indentation."
  :type 'natnum
  :safe #'natnump
  :package-version '(sol-mode . "0.0.1"))

;;; -- Utilities --

(defconst solidity-language-source
  '(solidity . ("https://github.com/JoranHonig/tree-sitter-solidity"
                "v1.2.11"))
  "Tree-Sitter Solidity language source.")

;;;###autoload
(defun solidity-install-grammar ()
  "Install the Solidity tree-sitter grammar."
  (interactive)
  (unless (treesit-language-available-p 'solidity)
    (message "Installing Solidity tree-sitter grammar")
    (let ((treesit-language-source-alist `(,solidity-language-source)))
      (treesit-install-language-grammar 'solidity))))

;;; -- Font Locking --

(defconst sol-mode--font-lock-settings
  (treesit-font-lock-rules
   :default-language 'solidity

   :feature 'comment
   '((((comment) @font-lock-doc-face)
      (:match "\\(?:///[^/]\\|/\\*\\*[^*]\\)" @font-lock-doc-face))
     (comment) @font-lock-comment-face)

   :feature 'string
   '([(string)
      (hex_string_literal)
      (unicode_string_literal)
      (yul_string_literal)] @font-lock-string-face))
  "Font-lock settings for `sol-mode' buffers.")

;;; -- Major Mode --

(defvar sol-mode-syntax-table
  (let ((st (make-syntax-table)))
    (c-populate-syntax-table st)
    (modify-syntax-entry ?$ "_" st)
    st)
  "Syntax table used in `sol-mode' buffers.")

(defvar sol-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map prog-mode-map)
    map)
  "Mode map for `sol-mode' buffers.")

;;;###autoload
(define-derived-mode sol-mode prog-mode "Solidity"
  "Major mode for editing Solidity code.

Key Bindings:
\\{sol-mode-map}"
  :syntax-table sol-mode-syntax-table
  (when (treesit-ready-p 'solidity)
    (treesit-parser-create 'solidity)

    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip "\\(?://+\\|/\\*+\\)\\s *")

    (setq-local treesit-font-lock-settings sol-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment)
                  (string)))

    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sol\\'" . sol-mode))

(provide 'sol-mode)
;;; sol-mode.el ends here
