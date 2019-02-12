# Make includes: include.mk

This is manual fork of [a collection of `make` includes](https://github.com/smaslennikov/include.mk). It includes documentation and information internal to SADA Systems, Inc.

<!-- toc -->

- [Usage](#usage)
- [Repository management](#repository-management)
    * [Development](#development)
- [Canned Client Documentation](#canned-client-documentation)
    * [Secret management](#secret-management)
        + [Recipients' public keys](#recipients-public-keys)
    * [Requirements for working with secrets](#requirements-for-working-with-secrets)
    * [Development with secrets](#development-with-secrets)
    * [Leak recovery](#leak-recovery)
- [Documentation](#documentation)
    * [Markdown](#markdown)
    * [Bastion host](#bastion-host)
    * [Terraform](#terraform)
        + [GCP](#gcp)
    * [Kubernetes](#kubernetes)
        + [EKS](#eks)
        + [Helm](#helm)
    * [Crypto Includes](#crypto-includes)
        + [Ansible Vault](#ansible-vault)
        + [SSH](#ssh)
        + [GnuPG](#gnupg)
- [Licensing](#licensing)

<!-- tocstop -->

## Usage

An example [`Makefile`](Makefile) shows how to include this repository dynamically in your own. Variables are to be overridden outside of `include.mk`; targets can also be overridden _or_ added to (e.g. `encrypt::` will add to the currently defined target).

Of course, you'll need to change the `GITROOT` variable in your `Makefile`s: it'll likely be the same as the example, but without the trailing `../`.

## Repository management

This is a manual fork of the [original repo](https://github.com/smaslennikov/include.mk) to allow for some flexibility:

- keeping this repository private allows us to stop supporting client resources using this code at the end of an SOW,
- including internal documentation _at the source_ but without making it public

### Development

To accept upstream changes:

1. Add the upstream remote: `git remote add upstream git@github.com:smaslennikov/include.mk.git`
2. Pull upstream commits, rebasing the ones here on top: `git pull upstream master --rebase`
3. Resolve any new conflicts following `git` guidelines
4. Force push to `sadasystems`: `git push origin master -f`

## Canned Client Documentation

The following are examples of docs that can be largely pasted into clients' repositories, with some modifications, comments for which are marked with `${SADA_COMMENT: }`. Be sure to fill those out before checking these in!

### Secret management

We currently store secrets within this repository, encrypted _to_ everyone listed [here](include.mk/90-crypt.mk) _by_ the `-u`-listed key in that same file (if `-u` flag isn't listed, your default private key is used).

Secrets are [`.gitignore`](.gitignore)d; their respective `.asc`s are checked in.

#### Recipients' public keys

| User | Key location |
|-|-|
|${SADA_COMMENT: list initial set of keys here, checking public keys into `keys/` directory and linking individuals to each}| |
| slava.maslennikov@sadasystems.com | [Keybase](https://keybase.io/smaslennikov) |

### Requirements for working with secrets

1. `gpg --import` public keys above
2. Someone from the [crypt user list](include.mk/90-crypt.mk) must reencrypt all secrets to you with `make reencrypt`

### Development with secrets

Makefile targets are present to facilitate the business:

- set the name of the secret(s) and encrypt them (for permanent secrets, the variable is set in the local Makefile): `ENCRYPTABLE=secretstuff.yaml make encrypt`
- decrypt is just as intuitive, assuming the variable is set in the local Makefile: `make decrypt`
- reencrypt all the secrets deeper than current directory to current recipients `make reencrypt`

### Leak recovery

Lost a secret?

1. Regenerate the secret
2. Run `ENCRYPTABLE=secretfile make encrypt`, setting the variable properly

Leaked a key?

1. Perform risk assessment: do you need to regenerate _all_ secrets? The answer is likely yes, here's an incomplete list of them:
    - ${SADA_COMMENT: list all initial secrets here, with processes for rotating them. Use the next line as an example and remove it.}
    - [Ansible controller's private SSH key](environments/v2-prod/secret/ssh_key.asc) used in CircleCI to execute Ansible Playbooks off it
       1. To rotate, generate a new ssh keypair with `make generate-ssh-key`,
       2. `terraform apply` to create the new host with the new key
2. `make reencrypt` all secrets

## Documentation

Variables listed should be set in a local `./Makefile`

### [Markdown](01-markdown.mk)

There's only one target here, `make toc`, which uses [`markdown-toc`](https://github.com/smaslennikov/markdown-toc) to generate tables of contents in a given (`MARKDOWN_FILE` variable) Markdown file.

- does so with proper indentation to support BitBucket,
- inserts the TOC at the comment location (`!-- toc --`, surrounded by `<>`. Can't paste it here or there are two places to place a toc!)

### [Bastion host](20-bastion.mk)

An opinionated target to SSH into an immutable bastion host: `make bastion` will

1. Call [`make decrypt`](#gnupg) if the private SSH key (`BASTION_SSH_KEY_FILE` variable) is not already decrypted,
2. `ssh` into `$BASTION_HOST` with `$BASTION_USERNAME` and `$BASTION_EXTRA_ARGS` while **ignoring host keys**

### [Terraform](30-terraform.mk)

Has a single target: `make output` calls `terraform output`. This is useful to work around [this bug](https://github.com/hashicorp/terraform/issues/20097).

#### [GCP](31-gcp.mk)

Has a single target: `make gproject` simply checks whether `GOOGLE_PROJECT` variable is set. This target is largely used as a dependency of others that require this variable.

### [Kubernetes](40-kubernetes.mk)

Has a single target: `make apply` will `kubectl apply -f ...` all `*.yaml` files in the directory. **It ignores** `*.yml` and doesn't simply apply `./`: it was a workaround for some subpar procedures at the time.

#### [EKS](41-eks.mk)

These are targets to facilitate some EKS operations:

|Command|Required Variables|End User target?|Purpose|
|-|-|-|-|
|`make dashboard`|none|Yes|Opens the proxied dashboard URL in your browser. Calls `make token`|
|`make token`|none|No|Spits out the token to be used to authenticate against the dashboard|
|`make kubeconfig`|`TERRAFORM_DIR`|Yes|Backs up your current `kubeconfig`, merges it with that generated by `make kubeconfig-eks`|
|`make kubeconfig-eks`|none|No|Simply spits out the generated EKS kubeconfig with `terraform output` in `TERRAFORM_DIR`|

The following variables are used here:

|Variable name|Default|Description|
|-|-|-|
|`TERRAFORM_DIR`|none|Relative path of your EKS terraform directory|

#### [Helm](42-helm.mk)

`make` targets are present to facilitate `helm` operations:

|Command|Required Variables|End User target?|Purpose|
|-|-|-|-|
|`make helm-install`|`RELEASE_NAME`, `VALUES_FILE`|Yes|Installs the specified release|
|`make helm-upgrade`|`RELEASE_NAME`, `VALUES_FILE`|Yes|Upgrades an existing release|
|`make helm-delete`|`RELEASE_NAME`|Yes|Deletes an existing release|
|`make helm-status`|`RELEASE_NAME`|Yes|Displays status of an existing release|

The following variables are used here:

|Variable name|Default|Description|
|-|-|-|
|`RELEASE_NAME`|none|Name of the release|
|`VALUES_FILE`|none|Which YAML of values to use|

### Crypto Includes

#### [Ansible Vault](91-ansible-vault.mk)

Facilitates Ansible Vault operations, takes care of the passphrase management.

|Command|Required Variables|End User target?|Purpose|
|-|-|-|-|
|`make vault_encrypt`|`VAULT_VARS_FILE`, `VAULT_PASSWORD_FILE`|Yes|Encrypts `VAULT_VARS_FILE` with passphrase in the file `VAULT_PASSWORD_FILE` (which should be encrypted with the [GnuPG](#gnupg) targets)|
|`make vault_decrypt`|`VAULT_VARS_FILE`, `VAULT_PASSWORD_FILE`|Yes|Decrypts as above|

**Each of the above operations cleans up after itself:** after `make vault_encrypt` you'll only have the encrypted file (`${VAULT_VARS_FILE}.enc`), whereas after a `make vault_decrypted` - only the plaintext version. This is to ensure that changes are committed properly.

The following variables are used here:

|Variable name|Default|Description|
|-|-|-|
|`VAULT_VARS_FILE`|`inventory/group_vars/all`|The file you want encrypted|
|`VAULT_PASSWORD_FILE`|`secret/vault_password`|The file containing the vault password|

**Ideally**, you'd set `ENCRYPTABLE=$(VAULT_PASSWORD_FILE)` in your local makefile and keep it encrypted with the [GnuPG](#gnupg) targets.

#### [SSH](92-ssh.mk)

Just one target in this include: `make generate-ssh-key` will generate an RSA SSH key using `SSH_KEY_FILE` and `SSH_KEY_COMMENT` variables.

**Ideally**, you'd set `ENCRYPTABLE=$(SSH_KEY_FILE)` in your local makefile and keep it encrypted with the [GnuPG](#gnupg) targets.

#### [GnuPG](93-gpg.mk)

Wraps GnuPG operations, allows for safely storing secrets in `git`.

|Command|Required Variables|End User target?|Purpose|
|-|-|-|-|
|`make generate-secret`|`CRYPTO_CHARS`, `CRYPTO_LENGTH`|Yes|Generates a secret using allowed `CRYPTO_CHARS` of length `CRYPTO_LENGTH`|
|`make generate-service-gpg-key`|`GPG_KEY_FILE`, `GPG_KEY_UID`|Yes|Generates a service GPG key (can be used for CI systems) with description of `GPG_KEY_UID` and exports to `GPG_KEY_FILE`|
|`make encrypt`|`ENCRYPTABLE`, `RECIPIENTS`|Yes|Iterates over list of files `ENCRYPTABLE`, encrypting all of them to public keys of `RECIPIENTS`|
|`make decrypt`|`ENCRYPTABLE`|Yes|Iterates over list of files `ENCRYPTABLE`, decrypting all of them|
|`make reencrypt`|None|Yes|Find all files `*.asc` (all encrypted files in the directory), encrypt them anew. Useful for key leaks|
|`make encryptable`|None|No|Checks that `ENCRYPTABLE` variable is set|

The following variables are used here:

|Variable name|Default|Description|
|-|-|-|
|`CRYPTO_CHARS`|`A-Za-z0-9-_`|A list of allowed characters to be used in `make generate-secret`|
|`CRYPTO_LENGTH`|`32`|Length of secret generated with `make generate-secret`|
|`GPG_KEY_FILE`|`secret/gpg_key`|Where to export your generated gpg key (`make generate-service-gpg-key`)|
|`GPG_KEY_UID`|none|Description of generated gpg key in `make generate-service-gpg-key`|
|`ENCRYPTABLE`|none|List of files (space separated) to be targeted with GPG make targets|
|`RECIPIENTS`|none|List of emails/UIDs of public keys to encrypt secrets to|

## Licensing

 * [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0): [`./LICENSE-APACHE`](LICENSE-APACHE)
 * [MIT License](https://opensource.org/licenses/MIT): [`./LICENSE-MIT`](LICENSE-MIT)

Licensed at your option of either of the above licenses.
