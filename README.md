# Sol-mode

This package provides a GNU Emacs major mode for editing Solidity code. Solidity is a statically-typed curly-braces programming language designed for developing smart contracts that run on Ethereum.

## Usage

This package is currently published to MELPA.

```emacs-lisp
;; Add MELPA package repository.
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))

;; Enable the `sol-mode' package.
(use-package sol-mode
  :ensure t
  :mode "\\.sol\\'")
```

## Tree-Sitter Grammar

This package requires the [JoranHonig/tree-sitter-solidity](https://github.com/JoranHonig/tree-sitter-solidity) grammar to be installed. A recipe is provided to make installing easier: `M-x solidity-install-grammar`.
