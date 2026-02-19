# Data Links Troubleshooting

## "Data link not found"

Bucket may not be registered as a data link. Use `--uri` with `--credentials` instead:

```bash
tw data-links browse --uri "s3://bucket" -c "credentials-name" -p "path"
```

## "Multiple DataLink items found"

Use `--id` instead of `--name` when there are duplicates:

```bash
tw data-links browse --id "v1-user-xxxxx" -p "path"
```

## "Unauthorized"

Check that `TOWER_ACCESS_TOKEN` is set and valid:

```bash
echo $TOWER_ACCESS_TOKEN | head -c 10
```

## Finding Credentials

List available credentials for your workspace:

```bash
tw credentials list -w <workspace>
```
