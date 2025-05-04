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

;;; References:

;; https://github.com/ethereum/emacs-solidity/blob/master/solidity-mode.el
;; https://github.com/bbatsov/neocaml/blob/main/neocaml.el
;; https://www.masteringemacs.org/article/lets-write-a-treesitter-major-mode

;;; TODO:

;; - Upstream `type Foo = uint256` highlight
;; - Upstream `boolean_literal` missing
;; - Upstream `using Foo for type` highlight
;; - Upstream `error Foo()` highlight
;; - Propose `// SPDX-License-Identifier:` highligh
;; - Upstream `transient` highlight

;;; Code:

(require 'c-ts-common)
(require 'cc-langs)
(require 'treesit)

;;; -- Configuration --

(defgroup solidity nil
  "Major mode for editing Solidity code."
  :prefix "solidity-"
  :group 'languages)

(defcustom solidity-indent-offset 4
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

;;; -- DEBUG --

(keymap-global-set
 "C-c C-x"
 (lambda ()
   (interactive)
   (eval-buffer "sol-mode.el")
   (with-current-buffer "Safe.sol"
     (revert-buffer-quick)
     (setq-local treesit--indent-verbose t))))
(keymap-global-set
 "C-c C-s"
 (lambda ()
   (interactive)
   (treesit-explore-mode +1)))

;;; -- Font Locking --

(defvar sol-mode--font-lock-settings
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
     [(string) (yul_string_literal)] @font-lock-string-face)
   :feature 'number
   '([(number_literal) (yul_decimal_number) (yul_hex_number)]
     @font-lock-number-face)
   :feature 'boolean
   '([(boolean_literal) (yul_boolean)] @font-lock-constant-face)

   :feature 'variable
   '([(identifier) (yul_identifier)] @font-lock-variable-name-face)

   :feature 'definition
   '((contract_declaration
      name: (identifier) @font-lock-type-face)
     (struct_declaration
      name: (identifier) @font-lock-type-face)
     (enum_declaration
      name: (identifier) @font-lock-type-face)
     (user_defined_type_definition
      name: (identifier) @font-lock-type-face)
     (function_definition
      name: (identifier) @font-lock-function-name-face)
     (modifier_definition
      name: (identifier) @font-lock-function-name-face)
     (constructor_definition
      "constructor" @font-lock-function-name-face)
     (fallback_receive_definition
      "fallback" @font-lock-function-name-face)
     (fallback_receive_definition
      "receive" @font-lock-function-name-face)
     (event_definition
      name: (identifier) @font-lock-type-face)
     (error_declaration
      name: (identifier) @font-lock-type-face)
     (constant_variable_declaration
      name: (identifier) @font-lock-variable-name-face)
     (state_variable_declaration
      name: (identifier) @font-lock-variable-name-face)
     (yul_function_definition
      :anchor
      (yul_identifier) @font-lock-function-name-face))

   :feature 'type
   '((type_name
      (identifier) @font-lock-type-face)
     (type_name
      (user_defined_type (identifier) @font-lock-type-face))
     (type_name
      "mapping" @font-lock-builtin-face)
     (import_directive
      import_name: (identifier) @font-lock-type-face)
     (inheritance_specifier
      ancestor: (user_defined_type (identifier) @font-lock-type-face))
     (using_directive
      (type_alias (identifier) @font-lock-type-face))
     (emit_statement
      :anchor
      (expression (identifier)) @font-lock-type-face)
     (revert_statement
      error: (expression (identifier)) @font-lock-type-face)
     (override_specifier
      (user_defined_type) @font-lock-type-face)
     [(primitive_type) (number_unit)] @font-lock-type-face)

   :feature 'statement
   '((call_expression
      function: (expression
                 (identifier) @font-lock-function-call-face))
     (call_expression
      function: (expression
                 (member_expression
                  property: (identifier) @font-lock-function-call-face)))
     (call_expression
      function: (expression
                 (struct_expression
                  type: (expression
                         (member_expression
                          property: (identifier)
                          @font-lock-function-call-face)))))
     (modifier_invocation (identifier) @font-lock-function-name-face)
     (yul_function_call
      function: (yul_identifier) @font-lock-function-call-face)
     (struct_member
      name: (identifier) @font-lock-property-name-face)
     (enum_value) @font-lock-constant-face
     (parameter
      name: (_) @font-lock-variable-name-face)
     (call_struct_argument
      name: (_) @font-lock-property-name-face)
     (struct_field_assignment
      name: (identifier) @font-lock-property-name-face)
     (event_parameter
      name: (_) @font-lock-variable-name-face)
     (error_parameter
      name: (_) @font-lock-variable-name-face)
     (member_expression
      property: (_) @font-lock-property-name-face)
     (yul_function_definition
      :anchor
      (yul_identifier)
      (yul_identifier) @font-lock-variable-name-face))

   :feature 'builtin
   :override t
   `((((member_expression
        object: (identifier) @font-lock-builtin-face property: (identifier)))
      (:match
       ,(rx bos (| "abi" "block" "msg" "tx") eos)
       @font-lock-builtin-face))
     (((call_expression
        function: (expression (identifier)) @font-lock-builtin-face))
      (:match
       ,(rx bos (|"addmod" "assert" "blobhash" "blockhash" "ecrecover"
                  "gasleft" "keccak256" "mulmod" "require" "ripemd160"
                  "selfdestruct" "sha256")
            eos)
       @font-lock-builtin-face))
     ["revert" (yul_evm_builtin)] @font-lock-builtin-face)

   :feature 'block
   :override t
   '((assembly_statement
      (assembly_flags
       (string) @font-lock-preprocessor-face)))

   :feature 'keyword
   '(["abstract" "as" "assembly" "break" "calldata" "case" "catch" "constant"
      "continue" "contract" "default" "do" "else" "emit" "enum" "error" "event"
      "external" "for" "from" "function" "if" "import" "indexed" "interface"
      "internal" "is" "let" "library" "memory" "modifier" "override" "payable"
      "private" "public" "pure" "return" "returns" "storage" "struct" "switch"
      "transient" "try" "type" "using" "var" "view" "while"
      (immutable) (unchecked) (virtual) (yul_leave)]
     @font-lock-keyword-face)

   :feature 'punctuation
   '(["{" "}" "[" "]" "(" ")"] @font-lock-bracket-face
     ["." "," ":" ";" "->" "=>"] @font-lock-delimiter-face
     (import_directive
      "*" @font-lock-misc-punctuation-face)
     (ternary_expression
      "?" @font-lock-misc-punctuation-face
      ":" @font-lock-misc-punctuation-face)
     ["&&" "||" ">>" "<<" "&" "^" "|" "+" "-" "*" "/" "%" "**" "=" "<" "<=" "=="
      "!=" ">=" ">" "!" "~" "-" "+" "++" "--" ":=" "delete" "new"]
     @font-lock-operator-face)

   :feature 'yul-label
   '((yul_label (identifier) @font-lock-constant-face))

   :feature 'comment
   '((((comment) @font-lock-preprocessor-face)
      (:match "\\`// SPDX-License-Identifier:" @font-lock-preprocessor-face))
     (((comment) @font-lock-preprocessor-face)
      (:match "\\`/// @solidity" @font-lock-preprocessor-face))
     (((comment) @font-lock-doc-face)
      (:match "\\`\\(?:///[^/]\\|/\\*\\*[^*]\\)" @font-lock-doc-face))
     (comment) @font-lock-comment-face))
  "Font-lock settings for `sol-mode' buffers.")

(defvar sol-mode--font-lock-feature-list
  '((comment definition)
    (keyword string number boolean yul-label)
    (pragma type statement builtin block punctuation)
    (variable))
  "Font-lock feature list for `sol-mode' buffers.")

;;; -- Indentation --

(defvar sol-mode--indent-rules
  `((solidity
     ((parent-is "source_file") column-0 0)

     ((node-is "}") standalone-parent 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)

     ((and (parent-is "comment") c-ts-common-looking-at-star)
      c-ts-common-comment-start-after-first-star -1)
     (c-ts-common-comment-2nd-line-matcher
      c-ts-common-comment-2nd-line-anchor 1)
     ((parent-is "comment") prev-adaptive-prefix 0)

     ((parent-is "pragma_directive") parent-bol solidity-indent-offset)
     ((n-p-gp nil nil "pragma_directive") grand-parent solidity-indent-offset)
     ((parent-is "import_directive") standalone-parent solidity-indent-offset)

     ((node-is ,(rx "_body" eos)) parent-bol 0)
     ((parent-is ,(rx "_body" eos)) parent-bol solidity-indent-offset)

     ((node-is "inheritance_specifier") parent-bol solidity-indent-offset)
     ((parent-is "\\`function_definition") parent-bol solidity-indent-offset)
     ((parent-is "modifier_definition") parent-bol solidity-indent-offset)
     ((parent-is "return_type_definition") parent-bol solidity-indent-offset)

     ((parent-is "error_declaration") parent-bol solidity-indent-offset)
     ((parent-is "event_declaration") parent-bol solidity-indent-offset)
     ((parent-is "constant_variable_declaration") parent-bol solidity-indent-offset)
     ((parent-is "state_variable_declaration") parent-bol solidity-indent-offset)
     ((parent-is "type_name") parent-bol solidity-indent-offset)
     ((parent-is "variable_declaration_tuple") parent-bol solidity-indent-offset)

     ((node-is "call_struct_argument") parent-bol solidity-indent-offset)
     ((parent-is "array_access") parent-bol solidity-indent-offset)
     ((parent-is "slice_access") parent-bol solidity-indent-offset)
     ((parent-is "struct_field_assignment") parent-bol solidity-indent-offset)
     ((parent-is "assignment_expression") parent-bol solidity-indent-offset)
     ((parent-is "augmented_assignment_expression") parent-bol solidity-indent-offset)
     ((parent-is "binary_expression") parent-bol solidity-indent-offset)
     ((parent-is "call_expression") parent-bol solidity-indent-offset)
     ((parent-is "meta_type_expression") parent-bol solidity-indent-offset)
     ((parent-is "parenthesized_expression") parent-bol solidity-indent-offset)
     ((parent-is "struct_expression") parent-bol solidity-indent-offset)
     ((parent-is "ternary_expression") parent-bol solidity-indent-offset)
     ((parent-is "tuple_expression") parent-bol solidity-indent-offset)
     ((parent-is "type_cast_expression") parent-bol solidity-indent-offset)
     ((parent-is "block_statement") parent-bol solidity-indent-offset)

     ;; TODO(nlordell): Member expressions are inversely nested (i.e. the first
     ;; one in the chain is the deepest in the tree) which means that the
     ;; indentation rules for member expressions don't quite work at the moment.
     ;; Since I don't think this is a common issue, just do a best effort for
     ;; now, expecially since Emacs 31 will introduce a new helper function
     ;; `c-ts-common-baseline-indent-rule' that solves this.
     ((parent-is "member_expression") parent-bol solidity-indent-offset)

     ((node-is "yul_label") standalone-parent 0)
     ((parent-is "assembly_statement") parent-bol solidity-indent-offset)

     ((n-p-gp "yul_block" "yul_function_definition" nil) parent-bol 0)
     ((n-p-gp "yul_block" "yul_if_statement" nil) parent-bol 0)
     ((n-p-gp "yul_block" "yul_for_statement" nil) parent-bol 0)
     ((parent-is "yul_block") parent-bol solidity-indent-offset)

     ((parent-is "yul_function_definition") parent-bol solidity-indent-offset)
     ((parent-is "yul_if_statement") parent-bol solidity-indent-offset)
     ((parent-is "yul_for_statement") parent-bol solidity-indent-offset)
     ((parent-is "yul_switch_statement") parent-bol 0)
     ((parent-is "yul_variable_declaration") parent-bol solidity-indent-offset)
     ((parent-is "yul_assignment") parent-bol solidity-indent-offset)
     ((parent-is "yul_function_call") parent-bol solidity-indent-offset)

     (no-node parent-bol 0)))
  "Indentation rules for `sol-mode' buffers.")

;;; -- Major Mode --

(defvar sol-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map prog-mode-map)
    map)
  "Mode map for `sol-mode' buffers.")

(defvar sol-mode--syntax-table
  (let ((st (make-syntax-table)))
    (c-populate-syntax-table st)
    (modify-syntax-entry ?$ "_" st)
    st)
  "Syntax table used in `sol-mode' buffers.")

;;;###autoload
(define-derived-mode sol-mode prog-mode "Solidity"
  "Major mode for editing Solidity code.

Key Bindings:
\\{sol-mode-map}"
  :syntax-table sol-mode--syntax-table
  (when (treesit-ready-p 'solidity)
    (c-ts-common-comment-setup)

    (setq-local electric-indent-chars
	            (append "{}():;," electric-indent-chars))
    (setq-local electric-layout-rules
	            '((?\; . after) (?\{ . after) (?\} . before)))

    (setq-local treesit-primary-parser (treesit-parser-create 'solidity))
    (setq-local treesit-font-lock-settings sol-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list sol-mode--font-lock-feature-list)
    (setq-local treesit-simple-indent-rules sol-mode--indent-rules)
    (treesit-major-mode-setup)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sol\\'" . sol-mode))

(provide 'sol-mode)
;;; sol-mode.el ends here
