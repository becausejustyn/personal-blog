# README

## Creating a New Blog Post

### 1. Create a New Post Directory

Create a new directory under `posts/` with a descriptive name for your post:

```bash
mkdir posts/your-post-name
```

**Example:** `posts/ggplot_colour_text`

### 2. Create the Post File

Inside your new directory, create a file named `post.qmd`:

```bash
touch posts/your-post-name/post.qmd
```

### 3. Add Frontmatter

Open `post.qmd` and add YAML frontmatter at the top:

```yaml
---
title: "Your Post Title"
author: "Your Name"
date: "2025-10-25"
categories: [category1, category2]
description: "A brief description of your post"
---
```

### 4. Write Your Content

Write your blog post content below the frontmatter using Markdown and Quarto features.

### 5. Add Images (Optional)

Place any images for your post in the same directory as `post.qmd`:

```
posts/your-post-name/
├── post.qmd
├── image1.png
└── image2.jpg
```

Reference images in your post using relative paths:

```markdown
![Image description](image1.png)
```

## Preview and Render

### Preview Your Blog Locally

To preview your blog with live reload:

```bash
quarto preview
```

This will open your blog in a browser and automatically refresh when you make changes.

### Render Your Blog

Before pushing to GitHub, render your blog to ensure everything builds correctly:

```bash
quarto render
```

This generates the HTML files in the `_site/` directory (or your configured output directory).

## Deployment

### Push to GitHub

Once you're satisfied with your post:

```bash
git add .
git commit -m "Add new post: your post title"
git push origin main
```

### Automatic Deployment

The blog is automatically deployed to Netlify via continuous integration when you push to GitHub. No additional steps are needed.

## Project Structure

```
.
├── posts/
│   ├── post-name-1/
│   │   ├── post.qmd
│   │   └── images...
│   ├── post-name-2/
│   │   ├── post.qmd
│   │   └── images...
│   └── ...
├── _quarto.yml          # Quarto configuration
└── index.qmd            # Blog homepage
```

## Tips

- Use descriptive directory names with underscores or hyphens (e.g., `data_visualization_tips`)
- Test your post locally with `quarto preview` before pushing
- Keep images in the same directory as your post for better organization
- Run `quarto render` to catch any build errors before deployment
