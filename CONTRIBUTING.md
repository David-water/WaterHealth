# Contributing

Thanks for helping improve WaterHealth. Small, focused contributions are welcome.

1. Open an issue describing the problem or proposed behavior before substantial changes.
2. Fork the repository and create a focused branch.
3. Run `make check` and `make test`; run `make mac` when changing shared/platform code.
4. For UI changes, include actual screenshots and exercise the affected native flow.
5. Explain the behavior change and validation in the pull-request template.

## Design and scope

Keep the app native and local-first. Do not add a backend, analytics, a third-party SDK or a package merely to replace a system capability. New dependencies should have a concrete need, a reviewed license and an explained size/privacy impact.

Views present state; `HealthStore` owns transactions. Persist successfully before publishing a changed archive. File imports must validate the entire batch before committing. Schema changes need a migration plan and failure-path tests.

Use `.system` fonts and accessible labels. App UI is currently Simplified Chinese; documentation changes should keep both root READMEs consistent. Do not represent demo age/risk numbers or simulated orders as clinical or commercial capabilities.

## Testing

- `make test`: business tests on an automatically chosen iPhone simulator.
- `WATERHEALTH_SIMULATOR=UUID make ui-test`: phone navigation/chat and goal smoke tests.
- The iPad landscape test is in `WaterHealthUITests`; select an iPad simulator when running it.
- Real-device HealthKit/notification checks must say which device, OS and permission states were exercised.

## Privacy and conduct

Be respectful and discuss the work, not the person. Use fictional records in all issues, fixtures and recordings. Never commit exported health archives, private keys, provisioning profiles or tokens. Report sensitive vulnerabilities through [private security reporting](SECURITY.md).

By contributing, you agree that your original contribution is provided under this repository's MIT License. Keep third-party credits and licenses intact.
