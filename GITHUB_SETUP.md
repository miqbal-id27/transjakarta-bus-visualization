# GitHub Setup Guide

Use this guide to publish the Transjakarta portfolio project to GitHub Pages.

## 1. Clone your GitHub repository

Open Terminal or Git Bash:

```bash
git clone https://github.com/miqbal-id27/transjakarta-public-bus-portfolio.git
cd transjakarta-public-bus-portfolio
```

If you use another repository name, replace `transjakarta-public-bus-portfolio` with your actual repo name.

## 2. Unzip the portfolio package

Unzip:

```text
transjakarta-public-bus-portfolio.zip
```

Inside it, you will see files and folders like:

```text
README.md
GITHUB_SETUP.md
.gitignore
docs/
notebooks/
src/
references/
```

Copy everything inside `transjakarta-public-bus-portfolio/` into your cloned repository folder.

Important: copy the contents inside the folder, not the ZIP file itself.

If Git asks whether to replace `README.md`, choose replace. If your existing repo already has a `LICENSE`, keep your existing license.

## 3. Check your repository folder

Your folder should look like this:

```text
transjakarta-public-bus-portfolio/
├── README.md
├── LICENSE                  # keep this if your repo already has it
├── .gitignore
├── GITHUB_SETUP.md
├── docs/
│   ├── index.html
│   ├── executive-summary.md
│   ├── project-process.md
│   ├── data-dictionary.md
│   └── data/
├── notebooks/
├── src/
└── references/
```

## 4. Commit and push

```bash
git status
git add .
git commit -m "Add Transjakarta interactive portfolio"
git push
```

After this, refresh GitHub. You should see the new folders:

```text
docs/
notebooks/
src/
references/
```

## 5. Enable GitHub Pages

On GitHub:

```text
Settings → Pages → Build and deployment
```

Choose:

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

Then click **Save**.

Your portfolio website will become:

```text
https://miqbal-id27.github.io/transjakarta-public-bus-portfolio/
```

Wait 1–5 minutes, then open the link.

## 6. Test locally before pushing

From the repository folder:

```bash
cd docs
python -m http.server 8000
```

Open:

```text
http://localhost:8000
```

Do not open `index.html` by double-clicking, because local JSON loading may fail under `file://`.

## 7. Alternative without Terminal

From your GitHub repository page:

```text
Add file → Upload files
```

Then drag the extracted folders and files into GitHub.

Terminal is still recommended because it handles existing files such as `README.md` and `LICENSE` more safely.
