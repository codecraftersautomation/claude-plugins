# PROFILE REPORT

_Template for a CCP profile diagnosis. The live version is generated at `.claude/ccp/PROFILE_DOCTOR.md`._

- Generated: {{GENERATED_AT}}
- Working directory: {{PWD}}
- Inside git repository: {{IS_GIT}}

## Launchers

- `claude`: {{CLAUDE_STATUS}}
- `claude-team`: {{TEAM_STATUS}}
- `claude-max`: {{MAX_STATUS}}

## Environment overrides (presence only — values never shown)

- `ANTHROPIC_API_KEY`: {{ENV_API_KEY}}
- `ANTHROPIC_AUTH_TOKEN`: {{ENV_AUTH_TOKEN}}
- `CLAUDE_CODE_USE_BEDROCK`: {{ENV_BEDROCK}}
- `CLAUDE_CODE_USE_VERTEX`: {{ENV_VERTEX}}
- `CLAUDE_CODE_USE_FOUNDRY`: {{ENV_FOUNDRY}}

## CCP state

- CCP plugin loaded (`${CLAUDE_PLUGIN_ROOT}` set): {{CCP_DIR}}
- `.claude/ccp` writable: {{CCP_WRITABLE}}

## Notes

{{NOTES}}
