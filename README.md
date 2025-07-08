# newproj

A Bash wizard script for quickly bootstrapping new projects with:

- Git repository initialization
- GitHub repository creation (public/private)
- npm project setup
- Tailwind CSS integration (v3 stable or v4 beta)

## Installation

```bash
mkdir -p "$HOME/bin" && cp newproj.sh "$HOME/bin/newproj" && chmod +x "$HOME/bin/newproj"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

## Usage

Simply run `newproj` and follow the interactive prompts.
