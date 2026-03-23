# Email

This repository manages the mail stack through Home Manager.

## Ownership

- Shared mail configuration lives in `common/email.nix`.
- Account definitions are declared in `accounts.email.accounts`.
- Generated configs come from Home Manager for:
  - `msmtp`
  - `mbsync`
  - `notmuch`
  - `neomutt`

## Accounts

The current accounts are:

- `gmail-tsl` (primary)
- `gmail-personal`
- `purelymail`

`common/email.nix` is the source of truth for:

- email addresses and usernames
- maildir paths
- SMTP and IMAP servers
- `mbsync` channel layout
- `neomutt` account switching and per-account sync macros

## Remaining raw fragments

These files are still intentionally maintained as mutt fragments and linked by
Home Manager:

- `mutt/bindings`
- `mutt/colors`
- `mutt/gpg.rc`
- `mutt/mailcap`

These are shared UI/behavior fragments, not account definitions.

Native `neomutt` ownership now includes:

- account registration and switching
- sidebar enablement and width
- most binds and macros

The remaining raw fragments are kept because they are either clearer as mutt
syntax (`colors`, custom GPG command wiring) or still shell-heavy (`bindings`,
`mailcap`).

## Generated paths

Home Manager generates:

- `~/.config/msmtp/config`
- `~/.config/isyncrc`
- `~/.config/notmuch/default/config`
- `~/.config/neomutt/neomuttrc`
- `~/.config/neomutt/<account-name>`

## Workflow notes

- `mbsync` state compatibility depends on channel names staying stable.
- The current channel names intentionally preserve the legacy names:
  - `sync-gmail-tsl-*`
  - `sync-gmail-personal-*`
  - `sync-purelymail-*`
- `neomutt` uses `msmtp` directly, not `msmtpq`.
- `notmuch` is configured, but indexing is not automatically triggered by this
  repo; run `notmuch new` explicitly when needed.
