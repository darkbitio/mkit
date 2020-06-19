<p align="center">
  <img src="images/logo-f14d61eb2fd0943650b496cccd7cfc5a.png">
</p>

# MKIT - Managed Kubernetes Inspection Tool

![MKIT](images/badge-v1.0.0.svg)

### Quickly discover key security risks of your managed GKE clusters and resources

**MKIT** is a Managed [Kubernetes](https://kubernetes.io) Inspection Tool that leverages FOSS tools to query and validate several common security-related configuration settings of managed Kubernetes cluster objects and the workloads/resources running inside the cluster. It runs entirely from a local Docker container and queries your cloud provider's APIs and the Kubernetes API to determine if certain misconfigurations are found. The same Docker container then launches a web UI to view and navigate the results on [localhost:8000](http://localhost:8000).

## Demo

View a live demo of the [web UI here](https://mkit.darkbit.io/).

[![web UI demo](images/demo-screen.png)](https://mkit.darkbit.io)

---

1. [Who is MKIT for?](#who-is-this-for)
1. [What does it check?](#what-does-mkit-check-for)
1. [What is it doing?](#what-does-it-do)
1. [Viewing Results](#viewing-results)
1. [Quick Start](#quick-start)
1. [Building Locally](#building-locally)
1. [Development](#development)

---

### Who is this for?

**MKIT** provides security-minded Google Kubernetes Engine (GKE) cluster administrators with a quick way to assess several common misconfigurations in their clusters and workloads.

### What does MKIT check for?

**MKIT** makes use of [Chef Inspec](https://inspec.io)-formatted profiles, and the GKE controls are published at the locations below:

- [https://github.com/darkbitio/inspec-profile-gke](https://github.com/darkbitio/inspec-profile-gke)
- [https://github.com/darkbitio/inspec-profile-k8s](https://github.com/darkbitio/inspec-profile-k8s)

### What does it do?

When running `make` with various parameters, the **MKIT** tool is leveraging your user credentials to query the GCP APIs for the specific cluster and validating its configuration. It then connects to the cluster directly via the Kubernetes API server to validate several configuration items inside the cluster. Finally, it combines those results into a format viewable by the [mkit-ui](http://localhost:8000) launched inside the `mkit` container listening on [http://localhost:8000](http://localhost:8000) for viewing.

### Sensitive Data

All results are stored inside the container for the life of that **MKIT** run, and they are not uploaded or shared in any way.

## Viewing Results

The **MKIT** web UI ([http://localhost:8000](http://localhost:8000)) shows all of the results on a single page. Failed checks appear first, followed by passed checks. Clicking **view all** will show all of the underlying resources impacted by the checks and whether they **passed** or **failed**.

![Results Overview](images/overview-screen-01701af71c95bc414e0580d6af069eb8.png)

## Quick Start

1. Clone this repository to your Linux / macOS / WSL2 system.

2. See the [section](#building-the-docker-image-manually) on building the image manually, if desired.

3. Ensure your identity has the following permissions:

   1. An IAM Role with `container.clusters.get` , `container.clusters.list`, and `container.clusters.getCredentials` . For example:
      1. `Owner` - `roles/owner`
      2. `Editor` - `roles/editor`
      3. `Kubernetes Engine Admin` - `roles/container.admin`
   2. Or, a custom IAM Role with `container.clusters.get`, `container.clusters.list`, `container.clusters.getCredentials`, and an in-cluster RBAC `ClusterRoleBinding` of the built-in `cluster-admin` or `view` ClusterRoles.

4. Authenticate with your Google Cloud credentials

    ```console
    gcloud auth application-default login
    ```

5. Run the following command (be sure to specify project-id and not project-name):

    ```console
    make run-gke project_id=my-project-id location=us-central1 clustername=my-gke-cluster-name
    ```
    ```console
    Running in darkbitio/mkit:latest: /home/node/audit/gke.sh
    Generating results...done.
    Fetching cluster endpoint and auth data.
    kubeconfig entry generated for my-gke-cluster.
    Generating results...done.

    Visit http://localhost:8000 to view the results
    yarn run v1.22.0
    node app.js
    
    MKIT Running - browse to http://localhost:8000
    ```

6. Visit [http://localhost:8000](http://localhost:8000) to view the results of the scan.

## Building Locally

If you prefer to build the Docker images locally before running, the **Dockerfile** is in this repo.

### Building the Docker image manually

1. Clone this repo
2. Modify the **Makefile** to name the image as desired
3. Run `make build` to build the container from scratch

## Development

We welcome any contributions from users in the community.

### Customizing/Extending the checks

1. Fork the desired profile repository
2. Modify the release tag and release URL to point to your new repository/release in the `Dockerfile`
3. Follow the steps in the previous [section](#building-the-docker-image-manually) to build a custom container using your new profile
