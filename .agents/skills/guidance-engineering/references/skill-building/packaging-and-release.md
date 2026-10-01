# Skill 打包、版本与发布

本参考只在目标是上传、共享、Plugin 打包、Responses API hosted Skill 或公开发布时读取。普通仓库内 Skill 不需要为了形式执行全部发布步骤。

## 先区分目标

### 本地 Git / 本地 Harness

每个 Skill 文件夹在作者环境中应由自己的本地 Git repository 管理。这个 Git 边界负责版本、回滚和 Case 历史；它不要求存在独立 GitHub / GitLab remote。

Harness 发现的是 Skill 目录及其内容，不依赖是否配置 remote。发布或上传 bundle 时，`.git/` 属于本地版本管理元数据，不应被当作 Skill 运行资源打包。重点仍是目录、description、instructions、supporting resources 和本地验证。

### Responses API hosted Skill

上传的是版本化 bundle。当前 API 支持 version pointer，例如 default/latest/显式 version。版本变更应保留可回滚关系，不要用“文件已更新”替代平台 version 状态。

### Plugin Skill

Plugin manifest 指向根 `skills/` 目录。当前官方示例包含 package name、semantic version、description 和 skills path。

如果 Skill 从 MCP server import，扫描得到的是 submission-time snapshot；服务端后续修改不会在已提交版本中自动实时更新，需要重新扫描并发布新版本。

## 发布测试

当前 Plugin submission 指南要求准备代表性测试。公开提交至少包括：

- 5 个 positive test cases；
- 3 个 negative test cases。

Positive case 应写：

- user prompt；
- expected tool / skill / workflow behavior；
- expected result shape；
- 必要 fixture/test account。

Negative case 应写：

- prompt/scenario；
- expected refusal / clarification / safe fallback；
- 为什么不应该完成该动作。

这属于发布/审核要求，不意味着每个本地实验 Skill 都必须机械维护固定 5+3；本地阶段仍应覆盖 direct/indirect/incomplete/non-trigger/edge cases。

## 版本语义

不要把 Git commit、Skill hosted version、Plugin semantic version 混成一个概念。

- Git commit：仓库历史；
- Skill version：hosted Skill bundle 版本；
- Plugin version：发布包版本。

变更记录应说明影响的是哪个层。

## 发布前核对

- final file tree 与本地测试一致；
- description 的触发边界经过代表性请求验证；
- dependencies 与实际工具一致；
- scripts 已执行验证；
- 安全审查完成；
- package manifest 与目标平台当前 schema 匹配；
- release notes 不夸大验证程度；
- 更新 Skill 后，如果平台使用 snapshot/import，确认重新扫描或重新上传。

当前官方依据：

- https://developers.openai.com/plugins/build/skills
- https://developers.openai.com/plugins/deploy/submission
- https://developers.openai.com/plugins/deploy/submission-errors
- https://developers.openai.com/api/docs/guides/tools-skills
