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

(require 'treesit)

(defgroup solidity nil
  "Major mode for editing Solidity code."
  :prefix "solidity-"
  :group 'langauges)

(defconst solidity-language-source
  '(solidity . ("https://github.com/JoranHonig/tree-sitter-solidity"
                "v1.2.11")))

(defvar sol-mode-syntax-table
  (let ((st (make-syntax-table)))
    st)
  "Syntax table used in `sol-mode' buffers.")

(defvar sol-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map prog-mode-map)
    map))

;;;###autoload
(define-derived-mode sol-mode prog-mode "Solidity"
  "Major mode for editing Solidity code.

Key Bindings:
\\{sol-mode-map}"
  :syntax-table sol-mode-syntax-table
  (when (treesit-ready-p 'solidity)
    (treesit-parser-create 'solidity)
    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sol\\'" . sol-mode))

(defun solidity-install-grammar ()
  "Install the Solidity tree-sitter grammar."
  (unless (treesit-language-available-p 'solidity)
    (message "Installing Solidity tree-sitter grammar")
    (let ((treesit-language-source-alist `(,solidity-language-source)))
      (treesit-install-language-grammar 'solidity))))

(provide 'sol-mode)
;;; sol-mode.el ends here
