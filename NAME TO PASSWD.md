# Generate Passwords Script: Setup and Usage Guide

This guide provides step-by-step instructions to set up and use a Python script for generating password variants from a list of names on Debian-based systems (tested on Debian 11/12). It includes optional extras like wordlists, hash generation, a man page, and safety notes. The script generates common password patterns (e.g., case variations, reversals, suffixes) for ethical cybersecurity learning or auditing.

## Prerequisites

- A Debian-based system (e.g., Debian 11 or 12).
- Root or sudo access for installations.
- Basic command-line knowledge.

## Step 1: Update System and Install Prerequisites

Update your package list and install required tools:

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip coreutils md5sum gzip
```

Optional useful tools for password cracking and wordlist generation:

```bash
sudo apt install -y john hashcat crunch wordlists
```

## Step 2: Create the Script

Save the following script as `~/generate_passwords`. This improved version includes a `--hash` option for outputting passwords in MD5, SHA1, or plain text.

```python
#!/usr/bin/env python3
# generate_passwords - global CLI password wordlist generator
# Usage:
#   generate_passwords users.txt passwords.txt
#   cat users.txt | generate_passwords - -
#   generate_passwords users.txt passwords.txt --hash md5

import argparse
import sys
from pathlib import Path
import hashlib

def build_variants(name):
    original = name
    lower = name.lower()
    capital = name.capitalize()
    upper = name.upper()
    reverse = name[::-1]
    reverse_lower = lower[::-1]
    reverse_capital = capital[::-1]

    bases = [original, lower, capital, upper, reverse, reverse_lower, reverse_capital]

    suffixes = ["", "123", "1234", "2024", "@123", "!", "01", "321", "@", "#"]
    patterns = []
    for base in bases:
        for suf in suffixes:
            patterns.append(base + suf)
        patterns.append(base + "@" + base)
        patterns.append(base + base[::-1])
    return patterns

def generate_passwords_from_names(names):
    seen = set()
    out = []
    for name in names:
        name = name.strip()
        if not name:
            continue
        for pwd in build_variants(name):
            if pwd not in seen:
                seen.add(pwd)
                out.append(pwd)
    return out

def read_lines(source):
    if source == "-":
        return [line.rstrip("\n") for line in sys.stdin]
    path = Path(source)
    if not path.exists():
        print(f"[!] Input file not found: {source}", file=sys.stderr)
        sys.exit(2)
    return [line.rstrip("\n") for line in path.open("r", encoding="utf-8")]

def write_lines(lines, dest, hash_mode):
    if hash_mode and hash_mode != "none":
        hfunc = {"md5": hashlib.md5, "sha1": hashlib.sha1}.get(hash_mode)
        if hfunc is None:
            print(f"[!] Unsupported hash: {hash_mode}", file=sys.stderr)
            sys.exit(3)
    else:
        hfunc = None

    if dest == "-":
        for line in lines:
            if hfunc:
                print(hfunc(line.encode()).hexdigest())
            else:
                print(line)
    else:
        Path(dest).parent.mkdir(parents=True, exist_ok=True)
        with open(dest, "w", encoding="utf-8") as f:
            for line in lines:
                if hfunc:
                    f.write(hfunc(line.encode()).hexdigest() + "\n")
                else:
                    f.write(line + "\n")
        print(f"[+] Generated wordlist: {dest} ({len(lines)} entries)")

def main():
    parser = argparse.ArgumentParser(description="Generate password wordlist variants from names (stdin/file).")
    parser.add_argument("input", help="Input file with names, one per line, or '-' for stdin")
    parser.add_argument("output", help="Output file to write wordlist, or '-' for stdout")
    parser.add_argument("--silent", "-q", action="store_true", help="Don't print the summary message")
    parser.add_argument("--count-only", action="store_true", help="Only print number of generated entries")
    parser.add_argument("--dedupe-only", action="store_true", help="Just dedupe input lines and output them")
    parser.add_argument("--hash", choices=["none","md5","sha1"], default="none", help="Output hashed passwords (md5/sha1)")
    args = parser.parse_args()

    lines = read_lines(args.input)
    if args.dedupe_only:
        deduped = []
        s = set()
        for l in lines:
            if l and l not in s:
                s.add(l)
                deduped.append(l)
        if args.count_only:
            print(len(deduped))
        else:
            write_lines(deduped, args.output, args.hash)
        return

    generated = generate_passwords_from_names(lines)
    if args.count_only:
        print(len(generated))
        return

    write_lines(generated, args.output, args.hash)
    if args.silent:
        return

if __name__ == "__main__":
    main()
```

Make the script executable:

```bash
chmod +x ~/generate_passwords
```

## Step 3: Install System-Wide

Move the script to a global location for easy access:

```bash
sudo mv ~/generate_passwords /usr/local/bin/generate_passwords
sudo chown root:root /usr/local/bin/generate_passwords
sudo chmod 755 /usr/local/bin/generate_passwords
```

Now, `generate_passwords` is available from any directory.

## Step 4: (Optional) Install Man Page

Create a man page for documentation (accessible via `man generate_passwords`):

```bash
sudo tee /usr/share/man/man1/generate_passwords.1 > /dev/null <<'MAN'
.TH generate_passwords 1 "User"
.SH NAME
generate_passwords \- generate password variants from names
.SH SYNOPSIS
generate_passwords INPUT OUTPUT [--hash md5|sha1]
.SH DESCRIPTION
Produces common password variants (case, reversed, suffixes) from input names.
.SH EXAMPLES
generate_passwords users.txt passwords.txt
cat users.txt | generate_passwords - -
generate_passwords users.txt passwords_md5.txt --hash md5
MAN
```

Update the man database:

```bash
sudo mandb >/dev/null 2>&1 || true
```

## Step 5: (Optional) Wordlists and Utilities

Install Debian's wordlists package:

```bash
sudo apt install wordlists
```

For RockYou wordlist (common in Kali; download if needed):

- Download `rockyou.txt.gz` from a trusted source.
- Unzip if necessary:

```bash
sudo gzip -d /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true
```

Use tools like `john` or `hashcat` with generated wordlists for ethical testing (e.g., `hashcat -m 0 hashes.txt passwords.txt`).

## Step 6: Examples of Use

Create a sample input file:

```bash
printf "Armour\nJohn\nRiya\n" > users.txt
```

Generate a plain wordlist:

```bash
generate_passwords users.txt passwords.txt
wc -l passwords.txt
head -n 20 passwords.txt
```

Generate MD5-hashed wordlist:

```bash
generate_passwords users.txt passwords_md5.txt --hash md5
```

Stream input/output:

```bash
cat users.txt | generate_passwords - - > passwords.txt
```

Count generated entries only:

```bash
generate_passwords users.txt - --count-only
```

Dedupe input only:

```bash
generate_passwords users.txt cleaned.txt --dedupe-only
```

## Step 7: Quick Tips and Extras

- Append to an existing file:

```bash
generate_passwords users.txt - >> passwords.txt
```

- Create password:MD5 pairs:

```bash
while IFS= read -r p; do echo "$p:$(printf '%s' "$p" | md5sum | awk '{print $1}')"; done < passwords.txt > passwords_md5_pairs.txt
```

- The script automatically deduplicates outputs while preserving order.

## Step 8: Safety and Ethics (Important)

- **Only use for owned systems**: Generate or test passwords only for accounts/systems you own or have explicit written permission to audit.
- **Legal compliance**: Unauthorized password cracking, account access, or distribution of cracked credentials is illegal (e.g., under CFAA in the US) and unethical.
- **Best practices**: Use strong, unique passwords in production. This tool is for educational purposes to demonstrate weak password risks.
- **Data handling**: Avoid storing generated wordlists insecurely; delete them after use.
- **Ethical auditing**: If testing, inform stakeholders and follow responsible disclosure.

## Step 9: Troubleshooting

- **Permission denied** when moving to `/usr/local/bin`: Ensure you're using `sudo`.
- **Command not found** after install: Verify `/usr/local/bin` is in your `$PATH` (run `echo $PATH`).
- **MD5 output issues**: Use the script's `--hash md5` or fall back to `md5sum` from coreutils.
- **Script errors**: Check Python version (requires Python 3) and file paths.

## Author

**Aditya Bhatt**  
Custom CLI script for wordlist generation and automation. Designed for cybersecurity learning and ethical password auditing.
