# SLATE Catalog Incubator Helm Charts

![CI/CD](https://github.com/slateci/slate-catalog-incubator/actions/workflows/release.yaml/badge.svg?branch=master&event=push)

## Overview

This repository is home to the *master* and *gh-pages* branches. It uses the [chart-releaser](https://github.com/helm/chart-releaser-action) GitHub Action to package charts in `/charts` on *master* and deploy them as GitHub Releases on *gh-pages*.

For more information on this process see [Chart Releaser Action to Automate GitHub Page Charts](https://helm.sh/docs/howto/chart_releaser_action/).

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add <alias> https://slateci.io/slate-catalog-incubator
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages. You can then run `helm search repo
<alias>` to see the charts.

To install the `<chart-name>` chart:

```shell
helm install my-<chart-name> <alias>/<chart-name>
```

To uninstall the chart:

```shell
helm delete my-<chart-name>
```
