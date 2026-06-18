---
layout: post
title: "新 npm 包的 main + beta 双通道发布：Trusted Publishing + semantic-release 全流程"
date: 2026-06-18
categories: [工程实践]
tags: [npm, trusted-publishing, oidc, semantic-release, github-actions, provenance, ci-cd]
description: "从 0 到 1 搭建 npm latest + beta 双通道自动发布，覆盖 Trusted Publishing（OIDC）、provenance 与 semantic-release 常见陷阱。"
image:
  path: /assets/img/post/npm-trusted-publishing-semantic-release/cover.png
  alt: "A minimalist digital illustration representing an automated CI pipeline with trusted publishing and semantic release"
---

> TL;DR：先用一次“正确的 bootstrap 发布”创建包，再把发布权完全交给 GitHub Actions OIDC + semantic-release。`main` 走 `latest`，`beta` 走 `beta`；bootstrap 之后不再手动 `npm publish` 或手动打版本 tag。

一份可复现的硬核实操手册：把一个全新仓库带到首个**自动化正式版**（`latest`）和
**预发布版**（`beta`）。技术方案围绕 **npm Trusted Publishing（OIDC）** + **构建
provenance（来源证明）**，由 **semantic-release** 基于 Conventional Commits 驱动版本。
**全程不需要长期保存的 `NPM_TOKEN`。**

> **进阶阅读**：如果你对 OIDC 的基础配置和原理不够熟悉，建议先阅读 [npm Trusted Publishing (可信发布) 配置指南](/posts/npm-trusted-publishing-guide/)；如果希望了解更广泛的自动化发版思路，可参考 [打造 GitHub Actions + Semantic Release 的极致 CI/CD 工作流](/posts/ci-cd-best-practices/)。

下面每一个坑都是真刀真枪踩过、修过的。它们的共同特征是：**测试 CI 早就绿了之后才发作**，
而且大多数不是直接报错，而是悄悄把发出去的产物搞坏。**Gotchas 那一节请读两遍。**

## 本文适用范围

- 你正在发布一个全新的 npm 包，希望同时维护 `latest`（稳定）和 `beta`（预发布）两个通道。
- 你希望做到“无长期密钥发布”：使用 npm Trusted Publishing（OIDC），而非长期保存 `NPM_TOKEN`。
- 你使用 GitHub Actions + semantic-release，且愿意遵循 Conventional Commits。

## 术语约定

- **Bootstrap 发布**：第一次手动发布，仅用于在 npm 上创建包并绑定 Trusted Publisher。
- **Trusted Publishing**：GitHub Actions 通过 OIDC 与 npm 交换短期凭据进行发布。
- **Provenance**：npm 发布时附带的构建来源证明（sigstore）。
- **通道（channel）**：语义上的发布轨道。本文中 `main -> latest`，`beta -> beta`。
- **Dist-tag**：npm 安装时的标签指针，例如 `latest`、`beta`。

---

## 1. 目标架构

```
 commit（Conventional Commits）
        │
        ├── push 到 main ──► semantic-release ──► X.Y.Z         ──► npm dist-tag: latest
        │                                     └─► GitHub Release + git tag + CHANGELOG
        │
        └── push 到 beta ──► semantic-release ──► X.Y.Z-beta.N  ──► npm dist-tag: beta
                                              └─►（同上，预发布通道）
```

- **版本号唯一真相来源：git tag + git notes，不是 `package.json`。**
- **两个通道、两条分支。** `main` → `latest`，`beta` → `beta`。
- **认证：GitHub Actions OIDC。** npm 校验 workflow 身份，签发短期发布令牌，无任何密钥落库。
- **provenance：开启。** 每个 tarball 附带一份 sigstore 签名证明，把它与确切的 commit +
  workflow run 绑定。

---

## 2. Bootstrap 鸡生蛋问题（先读这段）

Trusted Publisher 是**挂在一个已存在的包上**配置的：npmjs.com →
*Package* → *Settings* → *Trusted Publisher*，填 `owner/repo`、workflow 文件名、
（可选）GitHub Environment。

这就有个先有鸡还是先有蛋的问题：**你没法给一个还不存在的包配置 trusted publisher。**
所以**首次发布必须先把包创建出来**。

本文聚焦推荐路径：**方案 1（手动 bootstrap 发一次）**。关键点是：首发就要发一个“正确的”版本，
否则你会把第一个永久存在的 npm 版本搞坏（bin 被删、产物缺失）。另外，npm 对撤销与重发有
严格限制（见 Gotcha G 的 24h 同名锁）。

### 2.1 前置准备

- **npm 账号 + 验证邮箱。** 没有就 `npm adduser`。
- **scope 要对齐。** 包名 `@owner/pkg` 里的 `@owner` 必须等于你的 npm 用户名或你拥有的
  organization；否则 `npm publish` 会因无权限被拒。
- **2FA。** 若账号开了 2FA，发布要带 OTP（`--otp=123456`）或改用 granular automation token。
- **bootstrap 版本号选低位**，如 `0.0.1`（或 `0.1.0-alpha.0`）。它会永久留在 registry 上，
  别在它上面反复折腾；把它当成「一次性但真实」的占位首发。它先占着 `latest`，等你后续发正式版
  时再被覆盖。

### 2.2 最小但正确的包骨架

让 `npm publish` 一次过、且首个版本就是可用的，至少准备这些文件（CLI 类包示例）：

`package.json`（首发版本号 = `0.0.1`，其余字段直接用第 §3 的完整模板，关键是 `bin` 不带 `./`、
`prepack` 会自动构建）：
```jsonc
{
  "name": "@owner/pkg",
  "version": "0.0.1",
  "type": "module",
  "license": "MIT",
  "repository": { "type": "git", "url": "git+https://github.com/owner/repo.git" },
  "bin": { "pkg": "dist/bin/pkg.js" },
  "publishConfig": { "access": "public" },
  "scripts": {
    "build": "rm -rf dist && tsc -p tsconfig.build.json --noCheck",
    "prepack": "npm run build"
  },
  "files": ["dist"],
  "devDependencies": { "typescript": "^5.6.0" }
}
```

`tsconfig.build.json`（编译出 `dist/`，产物是普通 `.js`，能在任何安装者机器上跑）：
```json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2023",
    "outDir": "dist",
    "rootDir": ".",
    "declaration": false
  },
  "include": ["bin", "src"]
}
```

`bin/pkg.ts`（首行 shebang 必须有，tsc 会原样保留到产物）：
```ts
#!/usr/bin/env node
console.log("pkg: hello from the bootstrap release");
```

再加 `README.md` 和 `LICENSE`（npm 与 GitHub 都会识别根目录的这两个文件）。

#### 变体：纯 library（无 `bin`）

如果你发的是库而不是 CLI，骨架更简单——没有 `bin`，所以 **Gotcha C 完全不适用**；但
「发布前必须有产物」（Gotcha D）依然成立，`prepack` 照样兜底。库要额外做的是导出
**类型声明（`.d.ts`）** 和 **`exports` 入口**。

`package.json`：
```jsonc
{
  "name": "@owner/pkg",
  "version": "0.0.1",
  "type": "module",
  "license": "MIT",
  "repository": { "type": "git", "url": "git+https://github.com/owner/repo.git" },

  // 现代解析入口；同时保留 main/types 兼容老工具链
  "exports": { ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" } },
  "main": "dist/index.js",
  "types": "dist/index.d.ts",

  "publishConfig": { "access": "public" },
  "scripts": {
    "build": "rm -rf dist && tsc -p tsconfig.build.json",   // 注意：库要发 .d.ts，别用 --noCheck
    "prepack": "npm run build"
  },
  "files": ["dist"],
  "devDependencies": { "typescript": "^5.6.0" }
}
```

`tsconfig.build.json`（库要开 `declaration` 生成 `.d.ts`；`rootDir` 指向 `src` 让产物结构干净）：
```json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2023",
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true
  },
  "include": ["src"]
}
```

`src/index.ts`：
```ts
export function hello(name: string): string {
  return `hello, ${name}`;
}
```

发布前自检（库版——不查 bin，改查 `.js` + `.d.ts` 是否都进了包）：
```bash
npm install
npm run build
ls dist/index.js dist/index.d.ts
T=$(npm pack | tail -1)
tar -tzf "$T" | grep -E "dist/index\.(js|d\.ts)$"   # 运行时 + 类型都在
rm -f "$T"
```
> CLI 版用 `--noCheck` 只为快速产出可跑的 `.js`；**库版务必去掉 `--noCheck`**，因为类型错误会
> 直接污染你导出的 `.d.ts`，让下游的类型提示出错。其余步骤（2.3 之后的登录、发布、Trusted
> Publisher、基线 tag）两种形态完全一致。

### 2.3 发布前本地自检（务必做，别跳）

```bash
npm install
npm run build
ls dist/bin/pkg.js                         # 产物在不在

# 模拟打包，确认 bin 没被 npm 剥掉、文件确实进了 tarball（Gotcha C/D）
T=$(npm pack | tail -1)
tar -xzO "$T" package/package.json | node -p "JSON.parse(require('fs').readFileSync(0)).bin"
tar -tzf "$T" | grep dist/bin/pkg.js
rm -f "$T"
```
期望：第一条打印 `{ pkg: 'dist/bin/pkg.js' }`（不是 `undefined`），第二条打印出文件路径。
任一为空就先回头修 `bin`/构建，别发。

### 2.4 登录并发布

```bash
npm whoami || npm login
# scoped 公开包必须 --access public，否则默认 restricted，没有私有套餐会直接失败
npm publish --access public
# 开了 2FA 就：npm publish --access public --otp=123456
```
期望输出尾部：`+ @owner/pkg@0.0.1`。随后核对：
```bash
npm view @owner/pkg version       # 0.0.1
npm view @owner/pkg@0.0.1 bin     # { pkg: 'dist/bin/pkg.js' } —— bin 没丢
```

### 2.5 配置 Trusted Publisher，并打基线 tag

1. 上 npmjs.com → 该 package → **Settings → Trusted Publisher → GitHub Actions**，填
   `owner/repo`、workflow 文件名（如 `ci.yml`）、（可选）Environment。
2. 打一个**稳定基线 tag**，让 semantic-release 从 0.x 起步（Gotcha E）。这个 tag **不需要**
   git note——无 note 的 tag 会被默认归到 `null`（即正式/`latest`）通道，正好当基线：
   ```bash
   git tag 0.0.1 <bootstrap-commit-sha>     # 与你刚发布的 bootstrap 版本对齐
   git push origin 0.0.1
   ```
   此后 CI 在 beta 上：`feat` 从 `0.0.1` → `0.1.0` → beta → `0.1.0-beta.1`。

### 2.6 确认 OIDC 接通

bootstrap 之后，第一次由 CI 触发的发布里，应能在日志看到：
```
[@semantic-release/npm] ℹ Verifying OIDC context for publishing from GitHub Actions
[@semantic-release/npm] ℹ OIDC token exchange with the npm registry succeeded
```
看到这两行，就说明已彻底切到无 token 的 Trusted Publishing，手动 bootstrap 的历史使命结束——
**从此交给 CI（见 Gotcha G）。**

---

## 3. `package.json` —— 发布关键字段

```jsonc
{
  "name": "@owner/pkg",
  "version": "0.0.0-semantic-release",   // 发布时被忽略；semantic-release 会改写它
  "type": "module",
  "license": "MIT",

  // provenance 必需。必须解析到 OIDC 断言的那个仓库，否则报 E422。
  "repository": { "type": "git", "url": "git+https://github.com/owner/repo.git" },
  "homepage": "https://github.com/owner/repo#readme",
  "bugs": { "url": "https://github.com/owner/repo/issues" },

  // 不要带前导 "./" —— 见 Gotcha C。
  "bin": { "pkg": "dist/bin/pkg.js" },

  "publishConfig": { "access": "public" },

  "scripts": {
    "build": "rm -rf dist && tsc -p tsconfig.build.json --noCheck",
    "prepack": "npm run build",          // 手动 `npm pack`/publish 的兜底
    "typecheck": "tsc --noEmit",
    "test": "node --test 'test/**/*.test.ts'"
  },

  // 发布编译产物，不发源码。见 Gotcha D。
  "files": ["dist", "schemas", "docs"]
}
```

---

## 4. `.releaserc.json` —— semantic-release 配置

```json
{
  "branches": ["main", { "name": "beta", "prerelease": true }],
  "tagFormat": "${version}",
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    ["@semantic-release/npm", { "npmPublish": true, "provenance": true }],
    "@semantic-release/github",
    ["@semantic-release/git", {
      "assets": ["package.json", "package-lock.json", "CHANGELOG.md", "README.md"],
      "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
    }]
  ]
}
```

要点：

- `{ "name": "beta", "prerelease": true }` 才使 `beta` 成为**预发布通道**，产出
  `X.Y.Z-beta.N` 并发到 npm dist-tag `beta`。去掉 `prerelease`，`beta` 就变成普通稳定
  分支（「为什么我的 beta 发成了 `1.0.0` 正式版？」最常见的原因就是这个配置错误）。
- `provenance: true` 需要 `id-token: write` **以及**正确的 `repository.url`（Gotcha B）。
- `@semantic-release/git` 这步会把版本号 + CHANGELOG 提交回分支，带 `[skip ci]` 避免死循环。

---

## 5. Workflow —— `.github/workflows/ci.yml`

```yaml
name: CI
on:
  push:
    branches: [ main, beta ]
  pull_request:
    branches: [ main, beta ]

jobs:
  test:
    name: Test (Node ${{ matrix.node-version }})
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [22, 23]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm run typecheck
      - run: npm run build      # 在 PR 阶段就守住构建门禁，而不是等到发布时才炸
      - run: npm test

  release:
    name: Release
    needs: test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/beta')
    runs-on: ubuntu-latest
    permissions:
      contents: write        # semantic-release 推送 tag + release commit + notes
      issues: write
      pull-requests: write
      id-token: write        # 必需：OIDC trusted publishing + provenance 签名
      packages: write        # 仅当你还要 dual-publish 到 GitHub Packages
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0     # semantic-release 需要完整历史、全部 tag 和 notes
      - uses: actions/setup-node@v4
        with:
          node-version: "lts/*"
      - name: Upgrade npm for trusted publishing
        run: npm install -g npm@latest   # OIDC 需要 npm >= 11.5.1；Node LTS 仍自带 npm 10
      - run: npm ci
      - run: npm run build               # 在 publish 之前构建（Gotcha D）
      - name: Semantic Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}   # 用于建 GitHub Release + 推 tag；不是 npm token
        run: npx semantic-release@25
      - name: Dual publish to GitHub Packages
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: ./scripts/publish-github-packages.sh      # 可选；见 §6
```

注意这里**没有**什么：没有 `NPM_TOKEN`。发到 npmjs.org 完全靠 OIDC。那两个
`GITHUB_TOKEN` 是 GitHub 自动注入的 token，用于建 GitHub Release / 推送 release commit，
以及可选的 GitHub Packages 镜像——**Trusted Publishing 不替代它们**。

---

## 6. 可选：dual-publish 到 GitHub Packages 且 token 不泄漏

GitHub Packages **不支持** npm Trusted Publishing，它用 `GITHUB_TOKEN` 认证。让 token
不落盘的办法：往 `.npmrc` 写一个字面量 `${VAR}` 占位符，由 npm 在运行时展开：

```bash
#!/usr/bin/env bash
# scripts/publish-github-packages.sh
set -euo pipefail
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"   # 只做存在性校验 —— 绝不插值

version="$(node -p "require('./package.json').version")"
if [[ "$version" == *-* ]]; then
  tag="${version#*-}"; tag="${tag%%.*}"   # 0.1.0-beta.1 -> beta
else
  tag="latest"
fi

cleanup() { rm -f .npmrc; }
trap cleanup EXIT
{
  echo "@owner:registry=https://npm.pkg.github.com"
  echo '//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}'   # 单引号：npm 在运行时展开
} > .npmrc

npm publish --registry https://npm.pkg.github.com --tag "$tag" \
  || echo "GitHub Packages: nothing to publish or version already exists."
```

为什么安全：重定向是写进文件（不是 stdout），没有 `set -x`，而且**真 token 永不落盘**
——`.npmrc` 里始终只有字面量 `${GITHUB_TOKEN}`，npm 发布时才从环境变量替换。
**不要给这个脚本加 `set -x`。**

---

## 7. Gotchas —— 真正会咬人的部分

### A. OIDC 需要 npm ≥ 11.5.1；Node LTS 自带 npm 10
`setup-node` 配 `node-version: "lts/*"` 给你的是 npm **10.x**，它会**静默跳过** OIDC
交换，然后因为没有 `NPM_TOKEN` 而失败。release job 里务必 `npm install -g npm@latest`
（或把 Node 升到 24+）。缺这步的症状：明明配了 trusted publisher，发布却表现为未认证。

### B. provenance 需要匹配的 `repository.url`
缺失或为空的 `repository.url` 会在发布的最后一刻失败：
```
npm error 422 Unprocessable Entity - Error verifying sigstore provenance bundle:
  package.json: "repository.url" is "", expected to match
  "https://github.com/owner/repo" from provenance
```
把 `repository.url` 设为 `git+https://github.com/owner/repo.git`。

### C. `bin` 的值不能以 `./` 开头
在 npm 11.x 上实测：`"bin": { "pkg": "./dist/bin/pkg.js" }` 会在发布时被**静默剥离**：
```
npm warn publish "bin[pkg]" script name dist/bin/pkg.js was invalid and removed
```
tarball 里文件还在，但**发布出去的 manifest 没有 `bin`**，于是 `npm i -g` 装不出命令。
修法：去掉 `./` → `"dist/bin/pkg.js"`。验证要看打包后的 manifest，别只看文件清单：
```bash
T=$(npm pack | tail -1); tar -xzO "$T" package/package.json | node -p "JSON.parse(require('fs').readFileSync(0)).bin"; rm -f "$T"
```

### D. 构建必须在 publish *之前*，光靠 `prepack` 不够
npm 在 `npm publish` **开头**就**规整（normalize）** `package.json`、校验 `bin` 目标是否
存在——这一步**早于** `prepack` hook。全新 CI checkout 此刻还没有 `dist/`，于是 npm 报
`No bin file found` 并把 bin 字段删掉。要在 release job 里、`npx semantic-release` **之前**
显式跑 `npm run build`。`prepack` 也保留，作为手动 `npm pack`/`npm publish` 的兜底。

（如果你想直接发 TypeScript：别。Node 拒绝对 `node_modules` 下的文件做类型擦除——
`ERR_UNSUPPORTED_NODE_MODULES_TYPE_STRIPPING`——所以 `.ts` 的 `bin` 在 `npm link` 下能跑，
对每一个真实安装者都是坏的。编译成 `.js`，让 `bin` 指向构建产物。）

### E. semantic-release 首次发布硬编码为 `1.0.0`
semantic-release **忽略 `package.json` 的 `version`**。没有任何历史发布 tag 时，它**不会**
从 `0.1.0` 起步——一个普通的 `feat` 首发会变成 **`1.0.0`**（在 beta 通道即 `1.0.0-beta.1`）。
想停在 1.0 以下，就在首跑前打一个稳定基线 tag，给 bump 运算一个下限：
```bash
git tag 0.0.0 <root-commit-sha>
git push origin 0.0.0
# 此后：feat -> 0.1.0 -> beta -> 0.1.0-beta.1
```

### F. 通道（channel）记录在 **git notes** 里，不只是 tag
semantic-release 把*某个版本发布到了哪个通道*记在 `refs/notes/semantic-release`。光有 tag
**不够**——note 缺失，semantic-release 就认不出该版本、从头重算。这在 `--debug` 之前都是
隐形的：
```
get-tags found tags for branch beta:
  [ { gitTag: '0.1.0-beta.1', version: '0.1.0-beta.1', channels: [ 'beta' ] } ]
```
如果 `channels` 为空/缺失，该 tag 对这条分支就会被忽略。

### G. **bootstrap 之后，永远不要手动 publish 或打 tag**
这是防止 A–F 叠加爆炸的元规则。手动 `npm publish` + 手动 `git tag` 会在 registry 上造出一个
semantic-release **没有 git note** 的版本，于是下一次运行它判定「无历史发布」、重算
`1.0.0-beta.1` 并尝试发布——接着撞上 npm 的 **24 小时同名锁**（unpublish 某版本后 24h 内
不能再发布同名版本号）和 **「cannot publish over a previously published version」** 错误。
这条连锁很难收拾。

如果你已经卡在这个状态，恢复办法是**把 semantic-release 本该写的那条 note 补上**、再让它继续：
```bash
# 把已存在的 0.1.0-beta.1 tag 所在 commit 关联到 beta 通道
git notes --ref semantic-release add -f -m '{"channels":["beta"]}' <tag-commit-sha>
git push origin refs/notes/semantic-release
# 之后一个普通的 fix:/feat: 提交就会得到 0.1.0-beta.2
```
用**你的真实配置**做 dry-run 验证（**不要**传 `--branches`，它会覆盖 `.releaserc` 并丢掉
`prerelease` 标志）：
```bash
GITHUB_TOKEN="$(gh auth token)" npx semantic-release@25 --dry-run --no-ci
# 期望：Found git tag 0.1.0-beta.1 ... The next release version is 0.1.0-beta.2
```

---

## 8. 端到端 runbook（空仓库 → npm 上首个 beta）

1. **搭骨架**：`package.json`（§3）、`tsconfig`、源码、测试。从第一个 commit 起就用
   Conventional Commits。
2. **在 npm 上 bootstrap 这个包**，好让 Trusted Publisher 能挂上去（§2 方案 1）：手动
   `npm publish --access public` 一次。
3. **配置 Trusted Publishing**：npmjs.com → package → Settings → Trusted Publisher →
   GitHub Actions → `owner/repo`、workflow `ci.yml`。
4. **提交 `.releaserc.json`（§4）和 `ci.yml`（§5）。**
5. *（若要停在 1.0 以下）* 打基线 tag（Gotcha E）：
   `git tag 0.0.0 <root-sha> && git push origin 0.0.0`。
6. **创建 `beta` 分支**并推一个 `feat:`/`fix:` 提交：
   ```bash
   git switch -c beta
   git commit -m "feat: initial public surface"
   git push -u origin beta
   ```
7. CI 跑起来：test → build → semantic-release。盯住 OIDC 成功那两行，以及
   `The next release version is 0.1.0-beta.1`。
8. **验证产物**，别只看绿勾：
   ```bash
   npm view @owner/pkg dist-tags          # beta -> 0.1.0-beta.1
   npm view @owner/pkg@0.1.0-beta.1 bin    # bin 没被删（Gotcha C）
   ```
9. **晋升正式版**：之后把 `beta` 合并到 `main`，semantic-release 切出 `0.1.0` 到 dist-tag
   `latest`。

---

## 9. 运作模型

- **Commit 即 API。** `fix:` → patch，`feat:` → minor，`feat!:` /
  `BREAKING CHANGE:` → major。`chore:`/`docs:` **不**触发发布。
- **每一次发布都归 CI。** bootstrap 之后，人类绝不手动 `npm publish` 或 `git tag`（Gotcha G）。
- **PR 门禁是 `typecheck + build + test`**，跨 Node 矩阵跑，把发布失败挡在合并之前。
- **公开包 provenance 不可省**：它是免费的供应链完整性保障，并且顺带强制了 `repository.url`
  的卫生。

整套系统归结为一句话：**写好 commit，push 到 `beta` 或 `main`，剩下交给基于身份的发布。**

## 10. 参考资料（建议发布前复核）

- npm docs: Trusted publishing with OIDC（GitHub Actions）
  https://docs.npmjs.com/trusted-publishers
- npm docs: Generating provenance statements
  https://docs.npmjs.com/generating-provenance-statements
- npm docs: `npm publish`
  https://docs.npmjs.com/cli/v11/commands/npm-publish
- npm docs: package.json `bin` / `files` / `repository`
  https://docs.npmjs.com/cli/v11/configuring-npm/package-json
- semantic-release docs（工作流与分支配置）
  https://semantic-release.gitbook.io/semantic-release/
- GitHub Actions docs: OIDC in GitHub Actions
  https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
