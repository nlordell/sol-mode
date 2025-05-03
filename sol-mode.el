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

;;; -- Syntax Table --

(defvar sol-mode--syntax-table
  (let ((st (make-syntax-table)))
    (c-populate-syntax-table st)
    (modify-syntax-entry ?$ "_" st)
    st)
  "Syntax table used in `sol-mode' buffers.")

;;; -- Font Locking --

(defconst sol-mode--font-lock-settings
  (treesit-font-lock-rules
   :default-language 'solidity

   :feature 'pragma
   '(["pragma" "solidity"] @font-lock-preprocessor-face
     (solidity_pragma_token "||" @font-lock-string-face)
     (solidity_pragma_token "-" @font-lock-string-face)
     (solidity_version_comparison_operator) @font-lock-operator-face
     (solidity_version) @font-lock-string-face)

   :feature 'string
   '((hex_string_literal "hex" @font-lock-string-face
                         (_) @font-lock-string-face)
     (unicode_string_literal "unicode" @font-lock-string-face
                             (_) @font-lock-string-face)
     [(string)
      (yul_string_literal)] @font-lock-string-face)
   :feature 'number
   '([(number_literal)
      (yul_decimal_number)
      (yul_hex_number)] @font-lock-number-face)
   :feature 'boolean
   '([(boolean_literal)
      (yul_boolean)] @font-lock-constant-face)

   :feature 'variable
   '([(identifier)
      (yul_identifier)] @font-lock-variable-name-face)

   :feature 'type
   '((type_name
      (identifier) @font-lock-type-face)
     (type_name
      (user_defined_type (identifier) @font-lock-type-face))
     (type_name
      "mapping" @font-lock-builtin-face)
     (contract_declaration
      name: (identifier) @font-lock-type-face)
     (inheritance_specifier
      ancestor: (user_defined_type (identifier) @font-lock-type-face))
     (using_directive
      (type_alias (identifier) @font-lock-type-face))
     (struct_declaration
      name: (identifier) @font-lock-type-face)
     (struct_member
      name: (identifier) @font-lock-property-name-face)
     (enum_declaration
      name: (identifier) @font-lock-type-face)
     (emit_statement
      :anchor
      (expression (identifier)) @font-lock-type-face)
     (user_defined_type_definition
      name: (identifier) @font-lock-type-face)
     (override_specifier
      (user_defined_type) @font-lock-type-face)
     [(primitive_type)
      (number_unit)] @font-lock-type-face)

   ;; TODO: state variable declaration
   ;; (state_variable_declaration name: (identifier))

   :feature 'function
   '((function_definition
      name: (identifier) @font-lock-function-name-face)
     (modifier_definition
      name: (identifier) @font-lock-function-name-face)
     (yul_evm_builtin) @font-lock-builtin-face
     (constructor_definition
      "constructor" @font-lock-function-name-face)
     (modifier_invocation
      (identifier) @font-lock-function-name-face)
     (call_expression
      :anchor
      (expression
       (member_expression
        (identifier) @font-lock-function-call-face)))
     (call_expression
      :anchor
      (expression (identifier) @font-lock-function-call-face))
     (event_parameter
      name: (_) @font-lock-variable-name-face)
     (parameter
      name: (_) @font-lock-variable-name-face)
     (yul_function_call
      function: (yul_identifier) @font-lock-function-call-face)
     (yul_function_definition
      :anchor
      (yul_identifier) @font-lock-function-name-face
      (yul_identifier) @font-lock-variable-name-face)
     (meta_type_expression "type" @keyword)
     (member_expression
      property: (_) @font-lock-property-name-face)
     (call_struct_argument
      name: (_) @font-lock-property-name-face)
     (struct_field_assignment
      name: (identifier) @font-lock-property-name-face)
     (enum_value) @font-lock-constant-face)

   :feature 'comment
   '((((comment) @font-lock-preprocessor-face)
      (:match "// SPDX-License-Identifier:" @font-lock-preprocessor-face))
     (((comment) @font-lock-doc-face)
      (:match "\\(?:///[^/]\\|/\\*\\*[^*]\\)" @font-lock-doc-face))
     (comment) @font-lock-comment-face))
  "Font-lock settings for `sol-mode' buffers.")

(defconst sol-mode--font-lock-feature-list
  '((comment pragma)
    (string number boolean)
    (type function)
    (variable))
  "Font-lock feature list for `sol-mode' buffers.")

;;; -- Major Mode --

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
  :syntax-table sol-mode--syntax-table
  (when (treesit-ready-p 'solidity)
    (treesit-parser-create 'solidity)

    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip "\\(?://+\\|/\\*+\\)\\s *")

    (setq-local treesit-font-lock-settings sol-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list sol-mode--font-lock-feature-list)

    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sol\\'" . sol-mode))

(provide 'sol-mode)
;;; sol-mode.el ends here
