# OLA Formula Modifications

This document tracks the minimal changes made to the upstream homebrew-core `ola`
formula to enable FTDI DMX support.

All modifications are marked with `# FTDI-MOD:` comments in the formula.

## Changes Summary

### 1. Description (line ~6)
```ruby
# FTDI-MOD: Updated description to indicate FTDI support
desc "Open Lighting Architecture for lighting control information (with FTDI DMX support)"
```

### 2. Dependency Added (line ~49)
```ruby
# FTDI-MOD: Added libftdi dependency for FTDI DMX support
depends_on "libftdi"
```

### 3. Configure Flag (line ~123)
```ruby
--enable-ftdidmx
# FTDI-MOD: Added --enable-ftdidmx above
```

### 4. Extended Caveats (line ~145)
Added FTDI configuration instructions to the caveats section.

### 5. Removed
- `bottle do` block (tap builds from source)
- `no_autobump!` directive (not applicable to taps)

## Maintenance Workflow

### Check for upstream changes
```bash
./scripts/sync-upstream.sh ola
```

### When upstream updates
1. Run the sync script to see what changed upstream
2. Copy the new upstream to `.upstream/ola.rb`
3. Re-apply the FTDI modifications (search for `FTDI-MOD` comments)
4. Test: `brew install --build-from-source joshantbrown/tap/ola`

### Quick update process
```bash
# 1. Check what changed
./scripts/sync-upstream.sh ola

# 2. If upstream changed, update stored reference
./scripts/sync-upstream.sh --update ola

# 3. Manually merge changes into Formula/ola.rb
# 4. Test the build
brew reinstall --build-from-source joshantbrown/tap/ola
```
