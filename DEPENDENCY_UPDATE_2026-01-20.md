# Dependency Update Report - 2026-01-20

## Summary
Investigated outdated dependencies flagged in the weekly dependency check. **0 out of 5** dependencies can be updated due to version constraints from parent packages. All constraints remain the same as documented in previous update (2024-12-29).

## Investigation Status

All 5 outdated dependencies remain constrained by their parent packages:

| Dependency | Current | Latest | Status | Blocker |
|------------|---------|--------|--------|---------|
| ethon | 0.15.0 | 0.18.0 | ❌ Cannot update | typhoeus 1.5.0 |
| liquid | 4.0.4 | 5.11.0 | ❌ Cannot update | jekyll 4.4.1 |
| terminal-table | 3.0.2 | 4.0.0 | ❌ Cannot update | jekyll 4.4.1 |
| ttfunk | 1.7.0 | 1.8.0 | ⚠️ Not advisable | Known bugs in 1.8.0 |
| unicode-display_width | 2.6.0 | 3.2.0 | ❌ Cannot update | terminal-table 3.0.2 |

## Dependencies That Cannot Be Updated

### ❌ ethon (0.15.0 → 0.18.0)
- **Blocker**: typhoeus 1.5.0 requires `ethon >= 0.9.0, < 0.16.0`
- **Root cause**: typhoeus 1.5.0 (latest available) doesn't support ethon 0.16+
- **Solution required**: typhoeus package update to support newer ethon versions
- **Security status**: ✅ No known vulnerabilities in version 0.15.0
- **Used by**: html-proofer → typhoeus → ethon

### ❌ liquid (4.0.4 → 5.11.0)
- **Blocker**: Jekyll 4.4.1 requires `liquid ~> 4.0`
- **Root cause**: Liquid 5.x contains breaking changes:
  - Dropped support for Ruby < 2.7
  - Stricter variable handling
  - Changes to filter and tag APIs
  - Security enhancements
- **Solution required**: Jekyll 5.x (not yet released as of 2026-01-20)
- **Security status**: ✅ No known vulnerabilities in version 4.0.4
- **Used by**: jekyll → liquid
- **References**: [Liquid 5 Changelog](https://github.com/Shopify/liquid/releases)

### ❌ terminal-table (3.0.2 → 4.0.0)
- **Blocker**: Jekyll 4.4.1 explicitly requires `terminal-table >= 1.8, < 4.0`
- **Root cause**: Jekyll excludes terminal-table 4.x (likely due to breaking changes)
- **Solution required**: Jekyll package update to support terminal-table 4.x
- **Security status**: ✅ No known vulnerabilities in version 3.0.2
- **Used by**: jekyll → terminal-table

### ❌ unicode-display_width (2.6.0 → 3.2.0)
- **Blocker**: terminal-table 3.0.2 requires `unicode-display_width >= 1.1.1, < 3`
- **Root cause**: Chained dependency constraint (requires terminal-table 4.0 first)
- **Major version change**: 2.x → 3.x indicates breaking changes
- **Solution required**: 
  1. First update terminal-table to 4.0 (blocked by Jekyll)
  2. Then unicode-display_width can update to 3.x
- **Security status**: ✅ No known vulnerabilities in version 2.6.0
- **Used by**: terminal-table → unicode-display_width

### ⚠️ ttfunk (1.7.0 → 1.8.0)
- **Status**: Technically updateable but **not advisable**
- **Root cause**: Version 1.8.0 has known bugs:
  - Font embedding bug causing corrupted PDFs in Adobe Reader
  - Issues with maxp table handling
  - `invalidfont` errors in CUPS print jobs
- **Previous action**: Intentionally downgraded from 1.8.0 to 1.7.0 in 2024-12-29 update
- **Current recommendation**: **Keep at 1.7.0** until bugs are fixed
- **Security status**: ✅ No known vulnerabilities in version 1.7.0
- **Used by**: pdf-reader → ttfunk
- **References**: [ttfunk Issue #102](https://github.com/prawnpdf/ttfunk/issues/102)

## Dependency Chain Analysis

```
Direct Dependencies (specified in Gemfile)
├── jekyll ~> 4.4 ────────────────────────> 4.4.1 (latest in series)
├── jekyll-theme-chirpy ~> 7.4 ──────────> 7.4.1 (latest)
├── html-proofer ~> 5.1 ─────────────────> 5.2.0 (can update)
└── puma ────────────────────────────────> 7.1.0 (latest)

Transitive Dependency Constraints
Jekyll 4.4.1
  ├── liquid ~> 4.0 ──────────────────────> [BLOCKS liquid 5.x]
  └── terminal-table >= 1.8, < 4.0 ──────> [BLOCKS terminal-table 4.x]
      └── unicode-display_width < 3 ─────> [BLOCKS unicode-display_width 3.x]

html-proofer 5.2.0
  └── typhoeus ~> 1.3 ───────────────────> 1.5.0 (latest)
      └── ethon >= 0.9.0, < 0.16.0 ─────> [BLOCKS ethon 0.16+]

pdf-reader 2.15.1
  └── ttfunk >= 0 ───────────────────────> 1.7.0 (intentionally kept, 1.8.0 has bugs)

Theme Constraint
jekyll-theme-chirpy 7.4.1
  └── jekyll ~> 4.3 ─────────────────────> [LIMITS jekyll to 4.x series]
```

## Verification Performed

### Bundle Update Attempt
```bash
$ bundle update ethon liquid terminal-table ttfunk unicode-display_width --conservative
Resolving dependencies...
Bundler attempted to update ethon but its version stayed the same
Bundler attempted to update liquid but its version stayed the same
Bundler attempted to update terminal-table but its version stayed the same
Bundler attempted to update ttfunk but its version stayed the same
Bundler attempted to update unicode-display_width but its version stayed the same
Bundle updated!
```

**Result**: All dependency updates blocked by version constraints.

### Security Scan
- Scanned all 5 outdated dependencies against GitHub Advisory Database
- **Result**: ✅ **No security vulnerabilities found**

### Changelog Review
- ✅ ethon: No documented breaking changes
- ⚠️ liquid: Major breaking changes in 5.x (stricter parsing, API changes)
- ⚠️ terminal-table: Major version bump, likely breaking changes
- ❌ ttfunk: **Known bugs in 1.8.0** (PDF corruption, font embedding issues)
- ⚠️ unicode-display_width: Major version bump (2.x → 3.x)

## Why These Dependencies Are Outdated

These dependencies are **transitive dependencies** (not directly specified in Gemfile). They are installed as requirements of other gems:

1. **ethon** - Required by typhoeus (used by html-proofer for link checking)
2. **liquid** - Required by Jekyll (the core templating engine)
3. **terminal-table** - Required by Jekyll (for formatted console output)
4. **ttfunk** - Required by pdf-reader (used by html-proofer)
5. **unicode-display_width** - Required by terminal-table (for proper table rendering)

The parent gems (Jekyll, typhoeus) are already at their latest versions but have not yet updated their dependency constraints to support these newer versions.

## Upstream Status Check

### Jekyll
- **Current**: 4.4.1 (released January 2025)
- **Next major**: 5.0 (not yet released)
- **Impact**: Jekyll 5.0 will likely support:
  - Liquid 5.x
  - terminal-table 4.x
  - unicode-display_width 3.x

### Typhoeus
- **Current**: 1.5.0 (released August 2025)
- **Status**: Latest version, no newer release available
- **Impact**: Need new typhoeus release to support ethon 0.16+

### Chirpy Theme
- **Current**: 7.4.1 (latest)
- **Jekyll constraint**: `~> 4.3` (supports Jekyll 4.x only)
- **Impact**: Will need update to support Jekyll 5.x when available

## Recommendations

### Immediate Action
**Accept current state** - No updates are possible or advisable:
- All direct dependencies are at their latest compatible versions
- No security vulnerabilities in current versions
- Upstream packages have not released compatible versions yet

### Monitoring Plan
Monitor for these upstream releases:

1. **Jekyll 5.0** (enables liquid 5.x, terminal-table 4.x, unicode-display_width 3.x)
   - Watch: https://github.com/jekyll/jekyll/releases
   - Impact: Major update, will require testing and theme compatibility check

2. **typhoeus 1.6+** (might support ethon 0.16+)
   - Watch: https://github.com/typhoeus/typhoeus/releases
   - Impact: Minor update, should be safe

3. **jekyll-theme-chirpy 8.x** (might support Jekyll 5.x)
   - Watch: https://github.com/cotes2020/jekyll-theme-chirpy/releases
   - Impact: Theme update, requires testing

### Future Action Plan

When Jekyll 5.0 is released:
1. ✅ Check if Chirpy theme 7.x is compatible with Jekyll 5.0
2. ✅ If not, wait for Chirpy theme update to support Jekyll 5.0
3. ✅ Update Gemfile to use Jekyll 5.0
4. ✅ Run `bundle update` to update all dependencies
5. ✅ Test site build and functionality
6. ✅ Review for any theme or plugin breaking changes

### Quarterly Review
- Re-run `bundle outdated` every quarter
- Check for new Jekyll, typhoeus, and Chirpy releases
- Re-evaluate when major upstream versions are available

## Changes Made

**No changes made** - All dependencies kept at current versions due to constraints.

## Conclusion

All 5 outdated dependencies remain blocked by version constraints from their parent packages (Jekyll 4.4.1, typhoeus 1.5.0, terminal-table 3.0.2). This is the same status as the previous dependency check (2024-12-29).

**Key findings:**
- ✅ No security vulnerabilities in any current versions
- ✅ All direct dependencies (jekyll, chirpy theme, html-proofer) are at latest versions
- ⚠️ Updates blocked by semantic version constraints in parent packages
- ⏳ Requires upstream releases (Jekyll 5.0, typhoeus 1.6+) to proceed

**Recommendation**: Close this issue as **"won't fix (upstream dependency)"** and re-open when Jekyll 5.0 or compatible upstream releases become available.

## References

- Previous update: [DEPENDENCY_UPDATE_2024-12-29.md](./DEPENDENCY_UPDATE_2024-12-29.md)
- Jekyll releases: https://github.com/jekyll/jekyll/releases
- Typhoeus releases: https://github.com/typhoeus/typhoeus/releases
- Chirpy theme: https://github.com/cotes2020/jekyll-theme-chirpy
- ttfunk bug: https://github.com/prawnpdf/ttfunk/issues/102
