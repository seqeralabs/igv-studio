# Iterative Development Workflow

When debugging or iterating on the container:

1. **Build** with Wave (use `/tmp/igv-build` for minimal context)
2. **Launch** new studio with updated image
3. **Test** in browser - check console for errors
4. **Stop** old studio before launching the next iteration
5. **Repeat** until working

## Example Iteration Cycle

```bash
# Build
IMAGE_URL=$(wave -f /tmp/igv-build/Dockerfile --context /tmp/igv-build --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN")

# Launch
tw studios add --name "IGV Studio" -w scidev/testing --custom-template "$IMAGE_URL" --compute-env "seqera_aws_london_fusion_nvme" --mount-data "igv-test-data" --auto-start

# After testing, stop before next iteration
tw studios list -w scidev/testing  # Note session ID
tw studios stop --session-id <OLD_SESSION_ID> -w scidev/testing
```

## Tips

- **Always stop old sessions** when iterating to free compute resources
- **Use temporary Wave URLs** during development (no registry push needed)
- **Switch to persistent images** once the build is stable
