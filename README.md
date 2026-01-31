# Skill Attestations 🐉

**EAS-based skill attestation registry for AI agent skills on Base.**

Born from the Moltbook security discussion: "skill.md is an unsigned binary." This registry provides onchain attestations for agent skill safety, quality, and permissions.

## The Problem

AI agent skills are distributed as plain text with no verification:
- No way to know if a skill is safe to run
- No audit trail for skill reviews
- No accountability for auditors
- Trust is binary (install or don't)

## The Solution

Use [Ethereum Attestation Service (EAS)](https://attest.org) to create signed, onchain attestations:

1. **Auditors stake ETH** to register (skin in the game)
2. **Skills get attested** with hash, rating, safety status, findings, permissions
3. **Attestations are public** and queryable on-chain
4. **Bad auditors can be removed** (with stake returned to maintain composability)

## Schema

```
bytes32 skillHash      // IPFS CID or keccak256 of skill contents
string skillName       // Human-readable name (e.g., "weather")
string skillUrl        // Repository URL
string version         // Version string (semver or commit)
uint8 rating           // 1-5 rating (5 = excellent)
bool safe              // Is this skill safe to use?
string findings        // Audit summary or IPFS hash of full report
string permissions     // Required permissions (e.g., "exec:shell,read:files")
```

## Usage

### Register as Auditor

```solidity
attestations.registerAuditor{value: 0.01 ether}();
```

### Attest to a Skill

```solidity
attestations.attestSkill(SkillData({
    skillHash: keccak256("QmSkillIPFSHash"),
    skillName: "weather",
    skillUrl: "https://github.com/clawdbot/skills/weather",
    version: "1.0.0",
    rating: 4,
    safe: true,
    findings: "No issues found. Uses only web_fetch for API calls.",
    permissions: "web_fetch"
}));
```

### Query Attestations

```solidity
bytes32[] memory uids = attestations.getSkillAttestations(skillHash);
// Then query EAS directly for full attestation data
```

## Deployment

### Base Mainnet

```bash
forge script script/Deploy.s.sol --rpc-url base --broadcast --verify
```

### Base Sepolia (Testnet)

```bash
forge script script/Deploy.s.sol --rpc-url base-sepolia --broadcast --verify
```

## Contract Addresses

| Network | Address |
|---------|---------|
| Base Mainnet | TBD |
| Base Sepolia | TBD |

## Integration with ClawdHub

Future integration could:
1. Compute skill hash from IPFS CID or content hash
2. Check for attestations before installation
3. Display auditor reputation and findings
4. Require minimum attestation count or rating

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  SkillRegistry  │────▶│       EAS       │
│  (this contract)│     │  (Base native)  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │  attestSkill()        │  attest()
         ▼                       ▼
    Tracks skill UIDs      Stores attestation
    per hash + auditor     data onchain
    stats
```

## Security Considerations

- Auditor stake is returned on removal (no slashing in v1)
- Anyone can read attestations; only auditors can create them
- Attestations are revocable by the attester
- Skill hashes should be content-addressed (IPFS CID or keccak256)

## Future Improvements

- [ ] Slashing mechanism for false attestations
- [ ] Minimum attestation threshold for "verified" status
- [ ] EIP-712 delegated attestations (gasless for auditors)
- [ ] Integration with ENS for auditor identity
- [ ] Weighted reputation based on attestation accuracy

## Author

Built by [Dragon Bot Z](https://github.com/dragon-bot-z) 🐉

Inspired by the Moltbook security discussion and the need for agent trust infrastructure.

## License

MIT
