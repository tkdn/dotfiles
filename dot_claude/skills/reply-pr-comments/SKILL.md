---
name: reply-pr-comments
description: GitHub PR のレビューコメントに返信するスキル。修正・議論が完了した後に、コンテキストを踏まえて返信草案を作成し、ユーザーの確認を得てから1件ずつ submit する。以下の場合に使用する: `/reply-pr-comments` を実行したとき、「PRコメントに返信して」「レビューコメントに返答したい」「コメントを返したい」などの発言があったとき。
---

# Reply PR Comments

Reply to review comments on the current branch's PR, one thread at a time, using the conversation context (fixes applied, commits made, discussion history) to draft each response. Get user confirmation before submitting each reply.

## Step 1: Identify the PR

```bash
GITHUB_TOKEN="" gh pr view --json number,url
```

If no PR is found, ask the user for the PR number.

## Step 2: Ask about already-replied threads

Before fetching comments, ask the user:

```
Should I skip threads where you've already replied, or review all threads?
```

## Step 3: Fetch inline comments

```bash
GITHUB_TOKEN="" gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '[.[] | {id: .id, in_reply_to_id: .in_reply_to_id, path: .path, line: .line, author: .user.login, body: .body}]'
```

Group comments into threads:
- A comment with `in_reply_to_id: null` is the root of a thread
- Comments sharing the same root belong to the same thread
- One thread = one reply

For each thread, identify the **last comment** (the most recent one in the thread). The key question is: who spoke last?

- If the current git user made the last comment → the thread is "replied"
- If someone else made the last comment → the thread needs attention, even if the user has posted earlier in the thread

Based on the answer in Step 2:
- Skip replied: exclude threads where the current git user's comment is the last one
- Review all: include every thread, but note which ones the user already replied to

## Step 4: Draft, confirm, and submit — one thread at a time

Process threads from top to bottom, one at a time.

### Drafting

Use the conversation context (what was fixed, which commits were made, what was discussed) to write a reply.

**Language**: Match the language of the reviewer's comment.

**Rules when replying in Japanese:**
- No expressions of gratitude or apology ("ありがとうございます", "すみませんでした", etc.)
- Be direct and clear — answer the point without preamble
- If a fix was committed, include the short commit hash in plain text — no Markdown formatting (write `a1b2c3d で対応しました`, not `` `a1b2c3d` で対応しました ``)
- Avoid unnecessary code-style Markdown (don't backtick-wrap model names, method names, etc. unless it genuinely aids readability)

### User confirmation

Present the draft to the user and ask for feedback. Incorporate any changes, then re-confirm. Proceed only when the user explicitly approves.

### Submit

Post the reply to the root comment of the thread:

```bash
GITHUB_TOKEN="" gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  --method POST \
  --field body="{reply body}"
```

Then move on to the next thread.

## Step 5: Wrap up

Once all threads have been addressed, let the user know.
