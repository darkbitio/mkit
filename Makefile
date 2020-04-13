# Copyright 2020 Darkbit.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL := /usr/bin/env bash

IMAGENAME=mkit
IMAGEREPO=darkbitio/$(IMAGENAME)
IMAGEPATH=$(IMAGEREPO):latest
HOMEDIR=/home/node
WORKDIR=${HOMEDIR}/audit
LOCALDIR=$(abspath $(dir ../))
CHECKK8S="k8s.sh"
CHECKGKE="gke.sh"
CHECKAKS="aks.sh"
CHECKEKS="eks.sh"

NDEF = $(if $(value $(1)),,$(error $(1) not set))

DOCKERBUILD=docker build -t $(IMAGEREPO):latest .

COMMAND=docker run --rm -it -p8000:8000 -v "$(PWD)/support/input.yaml":$(WORKDIR)/input.yaml

GKEDEVMOUNT=-v $(LOCALDIR)/inspec-profile-gke:$(HOMEDIR)/profiles/inspec-profile-gke \
  -v $(LOCALDIR)/inspec-profile-k8s:$(HOMEDIR)/profiles/inspec-profile-k8s
GKECOMMAND=$(COMMAND) \
  -v $(HOME)/.config/gcloud:$(HOMEDIR)/.config/gcloud \
  -e GOOGLE_AUTH_SUPPRESS_CREDENTIALS_WARNINGS=true
GKEINSPECRUN=$(GKECOMMAND) --entrypoint $(WORKDIR)/$(CHECKGKE) $(IMAGEPATH) "$(project_id)" "$(location)" "$(clustername)"

AKSDEVMOUNT=-v $(LOCALDIR)/inspec-profile-aks:$(HOMEDIR)/profiles/inspec-profile-aks \
  -v $(LOCALDIR)/inspec-profile-k8s:$(HOMEDIR)/profiles/inspec-profile-k8s
AKSCOMMAND=$(COMMAND) \
  -e AZURE_CLIENT_ID \
  -e AZURE_TENANT_ID \
  -e AZURE_CLIENT_SECRET \
  -e AZURE_SUBSCRIPTION_ID
AKSINSPECRUN=$(AKSCOMMAND) --entrypoint $(WORKDIR)/$(CHECKAKS) $(IMAGEPATH) "$(resourcegroup)" "$(clustername)"

EKSDEVMOUNT=-v $(LOCALDIR)/inspec-profile-eks:$(HOMEDIR)/profiles/inspec-profile-eks \
  -v $(LOCALDIR)/inspec-profile-k8s:$(HOMEDIR)/profiles/inspec-profile-k8s
EKSCOMMAND=$(COMMAND) \
  -v $(HOME)/.aws:/root/.aws:ro \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN \
  -e AWS_SECURITY_TOKEN \
  -e AWS_SESSION_EXPIRATION
EKSINSPECRUN=$(EKSCOMMAND) --entrypoint $(WORKDIR)/$(CHECKEKS) $(IMAGEPATH) "$(awsregion)" "$(clustername)"

K8SDEVMOUNT=-v $(LOCALDIR)/inspec-profile-k8s:$(HOMEDIR)/profiles/inspec-profile-k8s
K8SKUBECONFIG=$(or ${KUBECONFIG},${KUBECONFIG},$(HOME)/.kube/config)
K8SCOMMAND=$(COMMAND) \
  -v $(K8SKUBECONFIG):/${HOMEDIR}/.kube/config:ro
K8SINSPECRUN=$(K8SCOMMAND) --entrypoint $(WORKDIR)/$(CHECKK8S) $(IMAGEPATH)


.PHONY: build run-k8s run-gke run-aks run-eks shell shell-k8s dev-k8s shell-gke dev-gke shell-aks dev-aks shell-eks dev-eks
build:
	@echo "Building $(IMAGEREPO):latest"
	@$(DOCKERBUILD)

run-k8s:
	@echo "Running in $(IMAGEREPO):latest: $(WORKDIR)/$(CHECKK8S)"
	@$(K8SINSPECRUN) || exit 0
run-gke:
	$(call NDEF,project_id)
	$(call NDEF,location)
	$(call NDEF,clustername)
	@echo "Running in $(IMAGEREPO):latest: $(WORKDIR)/$(CHECKGKE)"
	@$(GKEINSPECRUN) || exit 0
run-aks:
	$(call NDEF,AZURE_CLIENT_ID)
	$(call NDEF,AZURE_TENANT_ID)
	$(call NDEF,AZURE_CLIENT_SECRET)
	$(call NDEF,AZURE_SUBSCRIPTION_ID)
	$(call NDEF,resourcegroup)
	$(call NDEF,clustername)
	@echo "Running in $(IMAGEREPO):latest: $(WORKDIR)/$(CHECKAKS)"
	@$(AKSINSPECRUN) || exit 0
run-eks:
	$(call NDEF,awsregion)
	$(call NDEF,clustername)
	@echo "Running in $(IMAGEREPO):latest: $(WORKDIR)/$(CHECKEKS)"
	@$(EKSINSPECRUN) || exit 0

shell:
	@echo "Running a shell inside the container"
	@$(COMMAND) $(IMAGEPATH) || exit 0
shell-k8s:
	@echo "Running a shell inside the container for K8s"
	@$(K8SCOMMAND) $(IMAGEPATH) || exit 0
dev-k8s:
	@echo "Running a profile dev shell inside the container for K8s"
	@$(K8SCOMMAND) $(K8SDEVMOUNT) $(IMAGEPATH) || exit 0
shell-gke:
	@echo "Running a shell inside the container for GKE"
	@$(GKECOMMAND) $(IMAGEPATH) || exit 0
dev-gke:
	@echo "Running a profile dev shell inside the container for GKE"
	@$(GKECOMMAND) $(GKEDEVMOUNT) $(IMAGEPATH) || exit 0
shell-aks:
	@echo "Running a shell inside the container for AKS"
	@$(AKSCOMMAND) $(IMAGEPATH) || exit 0
dev-aks:
	@echo "Running a profile dev shell inside the container for AKS"
	@$(AKSCOMMAND) $(AKSDEVMOUNT) $(IMAGEPATH) || exit 0
shell-eks:
	@echo "Running a shell inside the container for EKS"
	@$(EKSCOMMAND) $(IMAGEPATH) || exit 0
dev-eks:
	@echo "Running a profile dev shell inside the container for EKS"
	@$(EKSCOMMAND) $(EKSDEVMOUNT) $(IMAGEPATH) || exit 0
