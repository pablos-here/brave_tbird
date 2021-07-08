## brave_tbird

A smart-ish email client handler script for `Brave`.

This script runs `Thunderbird` when a `mailto` link is clicked in
`Brave`.

Under certain conditions, webmail may be used instead of
`Thunderbird`.

## Installation / upgrading

1. [Get the latest the
   release](https://github.com/pablo-blueoakdb/brave_tbird/releases),
   uncompress the file and switch to the newly created directory.
2. Copy `xdg-email-hook.sh` to a directory in your `$PATH`.  For
   example, `~/bin`:

```shell
cp xdg-email-hook.sh ~/bin
```

## Customization

### XDG_EMAIL_HOOK_WEBMAIL_URL

A user defined variable influences this script as follows:

| XDG_EMAIL_HOOK_WEBMAIL_URL | If Thunderbird is not running |
|----------------------------|-------------------------------|
| Not defined                | Start `Thunderbird`           |
| Defined or set to ""       | Use gmail in `Brave`          |
| Set to a Webmail URL       | Use the URL in `Brave`        |

#### Webmail URL

Specify a webmail URL fragment that needs the rest of the URL to be
provided.

For example ensure that it ends with something like `...&url=`  To the
right of the `=` will be provided.

## Set up

### Tweak brave handler

On `Brave`, ensure that there are not hanlders for email defined or
that `mail.google.com` is blocked:

```
brave://settings/handlers
```
### xdg-mime

Confirm that `Thunderbird` is the default email client.

The expected output from the command below is `thunderbird.desktop`:

```shell
xdg-mime query default 'x-scheme-handler/mailto'
```

#### KDE

On `KDE`, if the above output is not returned:

1. `System Settings > Applications > Default Applications`
2. Ensure that the `Email client` is set to `Thunderbird`.
