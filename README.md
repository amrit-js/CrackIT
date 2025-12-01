# ⚡ CrackIT — John the Ripper Wrapper Tool  
A safe, educational password-cracking demonstration tool.

CrackIT is a *Linux CLI tool* built around *John the Ripper*.  
It demonstrates *dictionary attacks* on:

- Hash files  
- ZIP files (via zip2john)  

This tool is *100% safe* because it only works on *user-provided files*, not system hashes.

---

## 🚀 Features

- Colorful banner UI  
- Menu-based interface  
- ZIP cracking support via zip2john  
- Hash cracking support  
- Wordlist-based dictionary attacks  
- Optional progress bar  
- Clean password-only output  
- Fully safe for educational use  

---

## 📦 Prerequisites

Install *John the Ripper*:

```bash
sudo apt install john
sudo apt installjohn
```

You also need:
• Bash
• Wordlist (Eg. wordlist.txt)

## Installation

Clone the Repository

```bash
git clone https://github.com/amrit-js/crackit.git
cd crackit
```

Make the script executable: 

```bash
chmod +x crackit.sh
```

Run:

```bash
./crackit.sh
```
