# GitHub Profile README - Claude Code instructions

## README Structure
- **Intro** - Brief bio with links to website/betterat.work
- **Project boxes** - Two-column table showcasing taskdn and Astro Editor (icons from project websites). These are the two major open source projects I'm working on right now. 
- **Elsewhere** - Three-column table of links (website, socials, other)
- **Latest** - Auto-updated three-column table (releases, writing, notes) with `<!-- marker -->` comments

## Auto-Update Script
`update-readme.sh` runs daily via GitHub Action. Edit the `REPOS` array at the top to add/remove release sources. Content between `<!-- X starts -->` and `<!-- X ends -->` markers is replaced.
