# [Feat]: Support compressed JSONL export for Audit Logs

## Background
With enterprise customer adoption, security audit teams need to periodically extract full API invocation logs for compliance. Currently, logs can only be browsed page-by-page in the web UI, impeding bulk analysis.

## Requirements
1. Add an "Export Logs" action button on the Admin Dashboard "Audit Logs" view;
2. Support date range filtering (Last 7 Days / 30 Days / Custom Range);
3. Asynchronously stream and compress logs into `.jsonl.gz` format in the backend;
4. Display a desktop/browser notification once ready, providing a secure one-time download link (valid for 2 hours).

## Related Issues
- **Related Requirement**: #45 (Add organization-level audit log persistence)
- **Dependency**: #38 (Implement pre-signed GCS/S3 upload & download tokens)

## Verification Steps
1. Navigate to Admin Console -> Audit Logs;
2. Select range: "Last 7 Days", click "Export";
3. Verify the export task is enqueued and notification appears within 3 seconds;
4. Download `.jsonl.gz`, decompress, and validate schema integrity via `jq .`.

## Acceptance Criteria
- Exporting 100,000 log entries completes in under 5 seconds with peak memory usage under 128MB (using streaming cursors);
- Exported JSONL includes `timestamp`, `actor`, `action`, `resource`, `ip`, and `status` fields, passing JSON schema validation.

## Priority
P1
