# Workspace Setup for Studio Git Integration

This guide covers the one-time workspace configuration needed before deploying any Dockerfile-based Studio via git integration. Once set up, creating studios is point-and-click.

> **This is not IGV-specific.** These steps apply to any custom Studio that uses `kind: "dockerfile"` in `.seqera/studio-config.yaml`.

## Overview

When you deploy a Studio from a git repo with a Dockerfile, Wave builds the image and pushes it to a container registry. The compute environment then pulls that image to run your Studio. This requires:

1. A container registry (ECR) to store built images
2. Platform configured to know where that registry is
3. A compute environment that can pull from it
4. (Private repos) A GitHub credential

## Step 1: Create an ECR Repository

Wave needs somewhere to push built images. Create an ECR repo in the **same region** as your compute environment:

```bash
aws ecr create-repository \
  --repository-name <your-org>/studios \
  --region <your-region> \
  --profile <your-aws-profile>
```

Example:
```bash
aws ecr create-repository \
  --repository-name scidev/studios \
  --region eu-west-2 \
  --profile sci-dev-playground
```

Note the full URI — you'll need it next:
```
<account-id>.dkr.ecr.<region>.amazonaws.com/<your-org>/studios
```

## Step 2: Configure Container Repository in Platform

1. Go to your workspace in Seqera Platform
2. **Settings** → **Studios** → **Container repository**
3. Enter the full ECR URI from Step 1
4. Click **Update**

> Without this, studio creation fails with: `Attribute 'buildRepository' must be specified when using freeze mode`

## Step 3: Add Registry Credentials

Wave needs credentials to **push** to ECR, and the compute environment needs credentials to **pull**.

### For push (Wave → ECR)

Add a **container registry credential** in the workspace:

1. **Credentials** → **Add Credentials**
2. **Provider:** Container Registry
3. **Name:** e.g. `ecr-studios`
4. **Registry:** `<account-id>.dkr.ecr.<region>.amazonaws.com`
5. Leave username/password empty (ECR uses IAM-based auth via the workspace's AWS credentials)

Alternatively, if the workspace already has AWS credentials with `ecr:*` permissions for the same account, those may be sufficient.

> Without this, studio creation fails with: `Missing credentials for container repository: <ecr-uri>`

### For pull (Compute → ECR)

If your compute environment runs in the **same AWS account** as the ECR repo, the Forge instance role usually has ECR access automatically.

If it runs in a **different account** (common with Forge — check the error for the account ID), add a cross-account pull policy:

```bash
aws ecr set-repository-policy \
  --repository-name <your-org>/studios \
  --region <your-region> \
  --profile <your-aws-profile> \
  --policy-text '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "AllowCrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<compute-account-id>:root"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ]
    }]
  }'
```

**How to find the compute account ID:** Launch the studio once — if it fails with `CannotPullImageManifestError`, the error message contains the instance role ARN with the account ID (e.g. `arn:aws:sts::063359189236:assumed-role/TowerForge-...`).

## Step 4: Compute Environment

Studios require specific compute environment types. Not all CE types work.

### What works

| Platform | Type | Status |
|----------|------|--------|
| AWS Batch | Forge, EC2 (on-demand) | ✅ Recommended |
| AWS Batch | Forge, Spot | ✅ Works (but sessions may be interrupted) |
| AWS Cloud | Single VM | ✅ Works |
| Google Cloud | Compute Engine | ✅ Works |

### What doesn't work

| Platform | Type | Status |
|----------|------|--------|
| Seqera Compute | Any | ❌ Silently fails during provisioning |
| AWS Batch | Forge with deleted credentials | ❌ Shows as INVALID |

### Create via Platform UI

1. **Compute Environments** → **Add Compute Environment**
2. **Platform:** AWS Batch
3. **Credentials:** AWS credentials with Batch + ECR permissions
4. **Region:** Same as your ECR repo
5. **Provisioning:** Forge
6. **Instance types:** m5.large or larger (2+ vCPU, 8+ GiB RAM recommended)
7. **Allocation strategy:** BEST_FIT_PROGRESSIVE
8. **Max CPUs:** 8 (or more if running multiple studios)
9. **Wave + Fusion:** Enable both

## Step 5: GitHub Credential (Private Repos Only)

If your Studio repo is private:

1. Create a [fine-grained GitHub PAT](https://github.com/settings/personal-access-tokens/new):
   - **Token name:** descriptive (e.g. `seqera-platform-studios`)
   - **Resource owner:** your org
   - **Repository access:** Only select the studio repo(s)
   - **Permissions → Contents:** Read-only
2. In Platform: **Credentials** → **Add Credentials** → **GitHub**
   - **Username:** your GitHub username
   - **Access token:** paste the PAT

## Verification Checklist

Before creating a studio, verify:

- [ ] ECR repository exists in the correct region
- [ ] Container repository path is set in Settings → Studios
- [ ] Container registry or AWS credentials exist in the workspace with ECR push access
- [ ] Cross-account ECR pull policy is set (if accounts differ)
- [ ] An AWS Batch (Forge, EC2) compute environment is AVAILABLE
- [ ] GitHub credential added (if repo is private)

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `buildRepository must be specified when using freeze mode` | No container repo in workspace settings | Step 2 |
| `Missing credentials for container repository: <uri>` | No ECR credential in workspace | Step 3 (push) |
| `CannotPullImageManifestError: ... not authorized to perform ecr:BatchGetImage` | Cross-account ECR pull denied | Step 3 (pull) |
| Studio stops during "Provisioning compute resources" (no error) | Wrong CE type | Step 4 — use AWS Batch, not Seqera Compute |
| `Associated credentials have been deleted` | CE uses deleted AWS credentials | Create a new CE with valid credentials |
| Build succeeds but studio never starts | CE in different region than ECR | Match CE region to ECR region |

## Reference

- [Seqera Docs: Import Studio from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Docs: Studios Overview](https://docs.seqera.io/platform-cloud/studios/)
- [AWS Docs: ECR Cross-Account Access](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html)
