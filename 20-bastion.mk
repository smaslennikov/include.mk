BASTION_HOST?=
BASTION_USERNAME?=
BASTION_EXTRA_ARGS?=
BASTION_SSH_KEY_FILE?=secret/id_rsa

.PHONY: bastion

bastion: $(BASTION_SSH_KEY_FILE)
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(BASTION_EXTRA_ARGS) $(BASTION_HOST) -l $(BASTION_USERNAME) -i $(BASTION_SSH_KEY_FILE)

$(BASTION_SSH_KEY_FILE):
	ENCRYPTABLE=$(BASTION_SSH_KEY_FILE) $(MAKE) decrypt
