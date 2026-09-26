> ⚠️ **This is a staged repository that is automatically synced to [NekoChan1108/kairos-apis](https://github.com/NekoChan1108/kairos-apis).**
>
> Contributions, including issues and pull requests, should be made to the main Kairos repository: [https://github.com/NekoChan1108/kairos](https://github.com/NekoChan1108/kairos).
>
> The [NekoChan1108/kairos-apis](https://github.com/NekoChan1108/kairos-apis) repository is read-only and used for importing only.

## Introduction

NekoChan1108/kairos-apis provides CRD types, informers, listers, and clientsets for Kairos custom resources.

## For Users

To use Kairos APIs in your project:

```go
import (
	kairosv1 "kairos.io/apis/pkg/apis/kairos/v1alpha1"
	kairosclient "kairos.io/apis/pkg/client/clientset/versioned"
)
```

## For Developers

### Making API Changes

1. Clone the main Kairos repository:

```shell
git clone https://github.com/NekoChan1108/kairos.git
```

2. Make changes in `staging/src/kairos.io/apis/`
3. Regenerate code if needed:

```shell
cd staging/src/kairos.io/apis
bash ./hack/update-codegen.sh
```

4. Submit a PR to the main Kairos repository
5. After merge, changes will be automatically synced to [NekoChan1108/kairos-apis](https://github.com/NekoChan1108/kairos-apis)

### Repository Structure

**This staging directory contains only the API code.** Repository-specific files are maintained separately:

- **Maintained in staging (synced to apis repo):**
    - `pkg/` - API definitions and generated code
    - `hack/` - Code generation scripts
    - `go.mod`, `go.sum` - Go module files
    - `README.md` - Basic documentation

- **Maintained only in [NekoChan1108/kairos-apis](https://github.com/NekoChan1108/kairos-apis) repo:**
    - `.github/` - GitHub workflows, issue templates
    - `.gitignore` - Repository-specific ignore patterns
    - `GOVERNANCE.md` - Governance documentation
    - `OWNERS` - Maintainer list
    - `SECURITY.md` - Security policy
    - `LICENSE` - License file

This separation ensures that repository governance and configuration remain independent between the main Kairos repository and the standalone APIs repository.